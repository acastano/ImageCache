import UIKit
import Foundation

final class ImageCache: NSObject, URLSessionDelegate {

    private let lock = NSLock()
    private let queue = OperationQueue()
    private let fileManager = FileManager.default
    private let downloadingURLs = NSMutableDictionary()
    private let memCache = NSCache<AnyObject, UIImage>()
    private let configuration = URLSessionConfiguration.default

    typealias ImageCompletion = (_ image: UIImage?, _ url: URL) -> Void

    class var imageCache: ImageCache {
        struct Singleton {
            static let instance = ImageCache()
        }
        return Singleton.instance
    }

    override init() {
        super.init()
        memCache.totalCostLimit = 50000000
        queue.maxConcurrentOperationCount = 100
        NotificationCenter.default.addObserver(self, selector:#selector(ImageCache.removeAll(notification:)), name: UIApplication.didReceiveMemoryWarningNotification, object:nil)
    }

    @objc func removeAll(notification: NSNotification) {
        memCache.removeAllObjects()
    }

    //MARK - Methods

    func loadImageWithURL(_ url: URL, completion: ImageCompletion?) {
        let path = filePath(url.absoluteString)
        if let image = localImage(path) {
            completion?(image, url)
        } else {
            operationExecution(url, path:path, completion:completion)
        }
    }

    func cancelImageForURL(_ url: URL) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            if let instance = self {
                instance.lock.lock()
                let absoluteURL = url.absoluteString
                if let operation = instance.downloadingURLs[absoluteURL] as? BlockOperation {
                    operation.cancel()
                }
                instance.downloadingURLs.removeObject(forKey: absoluteURL)
                instance.lock.unlock()
            }
        }
    }

    //MARK - Operation

    private func operationExecution(_ url: URL, path: String, completion: ImageCompletion?) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self] in
            if let instance = self {
                instance.processRemoteOperation(operation, url:url, path:path, completion:completion)
            }
        }
        lock.lock()
        downloadingURLs[path] = operation
        queue.addOperation(operation)
        lock.unlock()
    }

    private func processRemoteOperation(_ operation: Operation, url: URL, path: String, completion: ImageCompletion?) {
        remoteData(url, path: path) { [weak self] data in
            if let instance = self {
                if operation.isCancelled == false {
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
        }
    }

    //MARK - Helpers

    private func filePath(_ urlString: String?) -> String {
        var filePath = CacheUtils.path.value
        if let urlString = urlString, let url = URL(string:urlString) {
            filePath += "/" + CacheUtils.keyForURL(url)
        }
        return filePath
    }

    //MARK - Data

    private func localDataFromDisk(_ path: String) -> Data? {
        var data: Data?
        let attributes = [FileAttributeKey.modificationDate: Date()]
        try? fileManager.setAttributes(attributes, ofItemAtPath:path)
        let url = URL(fileURLWithPath: path)
        data = try? Data(contentsOf: url, options: .mappedIfSafe)
        return data
    }

    private func remoteData(_ url: URL, path: String, completion: @escaping ((Data?) -> Void)) {
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url, completionHandler: { data, response, _ in
            var returnedData: Data?
            if let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 400 {
                returnedData = data
                try? returnedData?.write(to: URL(fileURLWithPath: path), options: [])
            }
            completion(returnedData)
        })
        task.resume()
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
        var image = UIImage(data:data)
        if image != nil {
            image = image?.withRenderingMode(.alwaysOriginal)
        } else {
            try? fileManager.removeItem(atPath: path)
        }
        return image
    }

    //MARK - NSURLSessionDelegate

    func URLSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (Foundation.URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust:serverTrust))
        }
    }
}
