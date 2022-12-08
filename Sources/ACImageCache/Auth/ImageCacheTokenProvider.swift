import Foundation

public protocol ImageCacheTokenProvider {
    func getToken(completion: @escaping ((String?) -> Void))
}
