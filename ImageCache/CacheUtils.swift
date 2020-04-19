import Foundation

private let versionKey = "CFBundleShortVersionString"

final class Path {
    let value: String
    private let cacheFolder = "ImageCache"

    init() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        if var path = path, let bundleIdentifier = Bundle.main.bundleIdentifier {
            path += "/" + bundleIdentifier + "/" + cacheFolder
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            self.value = path
        } else {
            self.value = ""
        }
    }
}

public final class CacheUtils: NSObject {
    class var path: Path {
        struct Singleton {
            static let instance = Path()
        }
        return Singleton.instance
    }

    class func keyForURL(_ url: URL) -> String {
        let h = url.host != nil ? url.host! : ""
        let p = url.path
        let q = url.query != nil ? url.query! : ""

        let path = String(format:"%@%@%@", h, p, q)
        let doNotWant = CharacterSet(charactersIn: "/:.,")
        let charactersArray = path.components(separatedBy: doNotWant)
        let key = charactersArray.joined(separator: "")
        return key
    }

   public static func clearAfterThirtyDays() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            let path = self.path.value
            guard let dirContents = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }
            clearDirectoryContent(dirContents, path: path)
        }
    }

    private static func clearDirectoryContent(_ files: [String], path: String) {
        let thirtyDaysInSeconds: TimeInterval = 2592000
        let daysToCleanCacheInSeconds = thirtyDaysInSeconds

        for file in files {
            let filePath = "\(path)/\(file)"
            let attr = try? FileManager.default.attributesOfItem(atPath: filePath)

            guard let date = attr?[FileAttributeKey.modificationDate] as? Date else { return }
            let difference = Date().timeIntervalSince(date)

            guard difference > daysToCleanCacheInSeconds else { return }
            try? FileManager.default.removeItem(atPath: filePath)
        }
    }
}
