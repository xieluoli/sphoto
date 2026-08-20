import Photos
import PhotosUI
import SwiftUI

struct PhotoGridView: View {

    let model: PhotoLibraryModel

    @State private var viewingAsset: ViewedAsset?

    private static let columnCount = 3
    private static let spacing: CGFloat = 2

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let side = (geo.size.width - Self.spacing * CGFloat(Self.columnCount - 1)) / CGFloat(Self.columnCount)
                grid(thumbnailSide: side)
            }
            .navigationTitle("全部照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.authorization == .limited {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("选择更多照片", action: presentLimitedLibraryPicker)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !model.recycleBin.isEmpty {
                    RecycleBinBar(
                        count: model.recycleBin.count,
                        onRestore: { model.restoreLatest() },
                        onDelete: { Task { await model.deleteStaged() } }
                    )
                }
            }
        }
        .fullScreenCover(item: $viewingAsset) { viewed in
            PhotoDetailView(model: model, startingAt: viewed.id)
        }
    }

    @ViewBuilder
    private func grid(thumbnailSide: CGFloat) -> some View {
        if model.assets.isEmpty {
            ContentUnavailableView("没有可以浏览的照片", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(thumbnailSide), spacing: Self.spacing),
                        count: Self.columnCount
                    ),
                    spacing: Self.spacing
                ) {
                    ForEach(model.assets, id: \.localIdentifier) { asset in
                        ThumbnailView(asset: asset, sideLength: thumbnailSide)
                            .onTapGesture { viewingAsset = ViewedAsset(id: asset.localIdentifier) }
                    }
                }
            }
        }
    }

    private func presentLimitedLibraryPicker() {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let root = scene?.keyWindow?.rootViewController else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: root)
    }
}

/// fullScreenCover(item:) 需要一个 Identifiable，这里只包一层资源标识。
private struct ViewedAsset: Identifiable {
    let id: String
}
