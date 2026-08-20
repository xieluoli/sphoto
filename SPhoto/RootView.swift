import Photos
import SwiftUI

struct RootView: View {

    let model: PhotoLibraryModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch model.authorization {
            case .notDetermined:
                ProgressView("正在请求相册权限…")
            case .authorized, .limited:
                PhotoGridView(model: model)
            default:
                PermissionDeniedView()
            }
        }
        .task { await model.start() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await model.refreshAuthorization() }
        }
    }
}

private struct PermissionDeniedView: View {

    var body: some View {
        ContentUnavailableView {
            Label("没有相册权限", systemImage: "lock")
        } description: {
            Text("SPhoto 需要访问相册才能展示照片。请在系统设置里打开相册权限。")
        } actions: {
            Button("打开系统设置") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
