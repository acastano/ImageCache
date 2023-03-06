import SwiftUI

@available(iOS 13.0, *)
struct NetworkImage: View {
    @ObservedObject var model: NetworkImageModel

    init(urlString: String?) {
        model = NetworkImageModel(imageUrl: urlString)
    }

    var body: some View {
        Image(uiImage: model.image ?? UIImage())
            .onAppear {
                model.load()
            }
    }
}
