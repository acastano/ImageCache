import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, *)
public final class NetworkImageModel: ObservableObject {

    @Published public var image: UIImage?

    private let imageUrl: String?
    private let placeholder: String?
    private var currentImageURL: URL?

    public init(imageUrl: String?, placeholder: String? = nil) {
        self.imageUrl = imageUrl
        self.placeholder = placeholder
    }

    public func load() {
        let imageURL = imageUrl != nil ? URL(string: imageUrl!) : nil
        guard currentImageURL == nil || (currentImageURL == imageURL) == false || image == nil else { return }
        
        cancelLoading(currentImageURL)
        getImageFromCache(imageURL, placeholder: placeholder)
    }

    public func deleteCurrentImageFromCache() {
        guard let url = currentImageURL else { return }
        ImageCache.imageCache.removeImageFromCache(url)
    }

    private func cancelLoading(_ currentImageURL: URL?) {
        image = nil
        guard let url = currentImageURL else { return }

        let cache = ImageCache.imageCache
        cache.cancelImageForURL(url)
    }

    private func getImageFromCache(_ url: URL?, placeholder: String?) {
        currentImageURL = url
        let cache = ImageCache.imageCache
        let placeholdeImage = placeholder != nil ? UIImage(named: placeholder!) : nil
        image = placeholdeImage

        guard let url = url else { return }
        cache.loadImageWithURL(url) { [weak self] image, url in
            guard let instance = self, url == instance.currentImageURL else { return }
            instance.image = image == nil ? placeholdeImage : image
        }
    }
}
