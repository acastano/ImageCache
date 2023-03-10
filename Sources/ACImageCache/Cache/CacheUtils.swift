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
            value = path
        } else {
            value = ""
        }
    }
}

public final class CacheUtils: NSObject {
    static var path: Path {
        struct Singleton {
            static let instance = Path()
        }
        return Singleton.instance
    }

    static func keyForURL(_ url: URL) -> String {
        let host = url.host != nil ? url.host! : ""
        let path = url.path
        let query = url.query != nil ? url.query! : ""

        let urlString = String(format: "%@%@%@", host, path, query)
        let doNotWant = CharacterSet(charactersIn: "/:.,=")
        let charactersArray = urlString.components(separatedBy: doNotWant)
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
