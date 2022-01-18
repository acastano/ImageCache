import UIKit

public final class NetworkImageView: UIImageView {
    private var currentImageURL: URL?

    public func load(with image: String?, placeholder: String? = nil) {
        let imageURL = image != nil ? URL(string: image!) : nil

        guard currentImageURL == nil || (currentImageURL == imageURL) == false || image == nil else { return }

        cancelLoading(currentImageURL)
        getImageFromCache(imageURL, placeholder: placeholder)
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
