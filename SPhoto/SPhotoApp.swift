import SwiftUI

@main
struct SPhotoApp: App {

    @State private var model = PhotoLibraryModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .preferredColorScheme(.dark)
        }
    }
}
