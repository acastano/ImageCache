import UIKit
import Foundation

typealias ImageCompletion = (_ image: UIImage?, _ url: URL) -> Void

final class ImageCache: NSObject, URLSessionDelegate, ImageCacheProtocol {

    private let lock = NSLock()
    private let queue = OperationQueue()
    private let fileManager = FileManager.default
    private let downloadingURLs = NSMutableDictionary()
    private let memCache = NSCache<AnyObject, UIImage>()
    private let configuration = URLSessionConfiguration.default

    static let imageCache = ImageCache()

    private var testImageCache: ImageCacheProtocol?
    
    var tokenProvider: ImageCacheTokenProvider?

    static func startTesting(_ testImageCache: ImageCacheProtocol) {
        imageCache.testImageCache = testImageCache
    }

    static func stopTesting() {
        imageCache.testImageCache = nil
    }

    override init() {
        super.init()
        memCache.totalCostLimit = 50000000
        queue.maxConcurrentOperationCount = 100
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ImageCache.removeAll),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }

    @objc func removeAll() {
        guard testImageCache == nil else {
            testImageCache?.removeAll()
            return
        }

        memCache.removeAllObjects()
    }

    // MARK: - Methods

    func loadImageWithURL(_ url: URL, completion: ImageCompletion?) {
        guard testImageCache == nil else {
            testImageCache?.loadImageWithURL(url, completion: completion)
            return
        }

        let path = filePath(url.absoluteString)
        if let image = localImage(path) {
            completion?(image, url)
        } else {
            operationExecution(url, path: path, completion: completion)
        }
    }

    func cancelImageForURL(_ url: URL) {
        guard testImageCache == nil else {
            testImageCache?.cancelImageForURL(url)
            return
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
			guard let instance = self else { return  }
			instance.lock.lock()
			let absoluteURL = url.absoluteString
			if let operation = instance.downloadingURLs[absoluteURL] as? BlockOperation {
				operation.cancel()
			}
			instance.downloadingURLs.removeObject(forKey: absoluteURL)
			instance.lock.unlock()
        }
    }

    func removeImageFromCache(_ url: URL) {
        let path = filePath(url.absoluteString)
        memCache.removeObject(forKey: path as AnyObject)
        try? fileManager.removeItem(atPath: path)
    }

    // MARK: - Operation

    private func operationExecution(_ url: URL, path: String, completion: ImageCompletion?) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self] in
            if let instance = self {
                instance.processRemoteOperation(operation, url: url, path: path, completion: completion)
            }
        }
        lock.lock()
        downloadingURLs[path] = operation
        queue.addOperation(operation)
        lock.unlock()
    }

    private func processRemoteOperation(_ operation: Operation, url: URL, path: String, completion: ImageCompletion?) {
        remoteData(url, path: path) { [weak self] data in
			guard let instance = self, operation.isCancelled == false else { return }

			instance.lock.lock()
			var image: UIImage?
			if let data = data {
				image = instance.imageWithData(data, removeIfInvalid: path)
			}
			DispatchQueue.main.async {
				completion?(image, url)
			}
			instance.downloadingURLs.removeObject(forKey: path)
			instance.lock.unlock()
        }
    }

    // MARK: - Helpers

    private func filePath(_ urlString: String?) -> String {
        var filePath = CacheUtils.path.value
        if let urlString = urlString, let url = URL(string: urlString) {
            filePath += "/" + CacheUtils.keyForURL(url)
        }
        return filePath
    }

    // MARK: - Data

    private func localDataFromDisk(_ path: String) -> Data? {
        var data: Data?

		let attributes = [FileAttributeKey.modificationDate: Date()]
        try? fileManager.setAttributes(attributes, ofItemAtPath: path)

		let url = URL(fileURLWithPath: path)
        data = try? Data(contentsOf: url, options: .mappedIfSafe)

        return data
    }

    private func remoteData(_ url: URL, path: String, completion: @escaping ((Data?) -> Void)) {
        var urlRequest = URLRequest(url: url)
        if tokenProvider != nil {
            tokenProvider?.getToken { token in
                if let token = token {
                    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                urlRequest.setValue("*/*", forHTTPHeaderField: "Accept")
                urlRequest.setValue("*/*", forHTTPHeaderField: "Content-Type")
                Foundation.URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, _ in
                    var returnedData: Data?
                    if let response = response as? HTTPURLResponse,
                        response.statusCode >= 200 && response.statusCode < 400 {
                        returnedData = data
                        try? returnedData?.write(to: URL(fileURLWithPath: path), options: [])
                    }
                    completion(returnedData)
                }).resume()
            }
        } else {
            Foundation.URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, _ in
                var returnedData: Data?
                if let response = response as? HTTPURLResponse,
                    response.statusCode >= 200 && response.statusCode < 400 {
                    returnedData = data
                    try? returnedData?.write(to: URL(fileURLWithPath: path), options: [])
                }
                completion(returnedData)
            }).resume()
        }
    }

    private func localImage(_ path: String) -> UIImage? {
        var image = memCache.object(forKey: path as AnyObject)
        if image == nil, let data = localDataFromDisk(path) {
            image = imageWithData(data, removeIfInvalid: path)
            if let image = image {
                memCache.setObject(image, forKey: path as AnyObject, cost: data.count)
            }
        }
        return image
    }

    private func imageWithData(_ data: Data, removeIfInvalid path: String) -> UIImage? {
        var image = UIImage(data: data)
        if image != nil {
            image = image?.withRenderingMode(.alwaysOriginal)
        } else {
            try? fileManager.removeItem(atPath: path)
        }
        return image
    }

    // MARK: - NSURLSessionDelegate

    func URLSession(_ session: Foundation.URLSession,
                    dataTask: URLSessionDataTask,
                    didReceiveResponse response: URLResponse,
                    completionHandler: (Foundation.URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else { return }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
