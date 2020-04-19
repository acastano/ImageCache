import UIKit

public final class NetworkImageView: UIImageView {
    private var currentImageURL: URL?

    public func load(with image: String?, placeholder: String? = nil) {
        let imageURL = image != nil ? URL(string: image!) : nil
        if currentImageURL == nil || (currentImageURL == imageURL) == false || image == nil {
            cancelLoading(currentImageURL)
            getImageFromCache(imageURL, placeholder: placeholder)
        }
    }

    private func cancelLoading(_ currentImageURL :URL?) {
        image = nil
        if let url = currentImageURL {
            let cache = ImageCache.imageCache
            cache.cancelImageForURL(url)
        }
    }

    private func getImageFromCache(_ url: URL?, placeholder: String?) {
        currentImageURL = url
        let cache = ImageCache.imageCache
        let placeholdeImage = placeholder != nil ? UIImage(named: placeholder!) : nil
        image = placeholdeImage

        if let url = url {
            cache.loadImageWithURL(url) { [weak self] image, url in
                if let instance = self {
                    if url == instance.currentImageURL {
                        instance.image = image == nil ? placeholdeImage : image
                    }
                }
            }
        }
    }
}
