import Foundation

protocol ImageCacheProtocol {
    func removeAll()
    func cancelImageForURL(_ url: URL)
    func loadImageWithURL(_ url: URL, completion: ImageCompletion?)
}

extension ImageCacheProtocol {
    func removeAll() {}
    func cancelImageForURL(_ url: URL) {}
}
