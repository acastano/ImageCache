import Foundation

protocol ImageCacheTokenProvider {
    func getToken(completion: @escaping ((String?) -> Void))
}
