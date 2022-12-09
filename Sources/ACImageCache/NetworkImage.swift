import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, *)
public final class NetworkImage: ObservableObject {

    var imageUrl: String?
    var placeholderImage: String?

    @Published var uiImage: UIImage?

    private var currentImageURL: URL?

    init(imageUrl: String?, placeholderImage: String?) {
        self.imageUrl = imageUrl
        self.placeholderImage = placeholderImage
    }

    public func load() {
        let imageURL = imageUrl != nil ? URL(string: imageUrl!) : nil

        guard currentImageURL == nil || (currentImageURL == imageURL) == false || uiImage == nil else { return }

        cancelLoading(currentImageURL)
        getImageFromCache(imageURL, placeholder: placeholderImage)
    }

    public func deleteCurrentImageFromCache() {
        guard let url = currentImageURL else { return }

        ImageCache.imageCache.removeImageFromCache(url)
    }

    private func cancelLoading(_ currentImageURL: URL?) {
        self.uiImage = nil
        guard let url = currentImageURL else { return }

        let cache = ImageCache.imageCache
        cache.cancelImageForURL(url)
    }

    private func getImageFromCache(_ url: URL?, placeholder: String?) {
        currentImageURL = url
        let cache = ImageCache.imageCache
        let placeholdeImage = placeholder != nil ? UIImage(named: placeholder!) : nil
        uiImage = placeholdeImage

        guard let url = url else { return }
        cache.loadImageWithURL(url) { [weak self] image, url in
            guard let instance = self, url == instance.currentImageURL else { return }
            instance.uiImage = image == nil ? placeholdeImage : image
        }
    }
}
