import Photos
import SwiftUI

struct ThumbnailView: View {

    let asset: PHAsset
    let sideLength: CGFloat

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .frame(width: sideLength, height: sideLength)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .task(id: asset.localIdentifier) {
                let side = sideLength * displayScale
                image = await PhotoImageProvider.thumbnail(
                    for: asset,
                    pixelSize: CGSize(width: side, height: side)
                )
            }
    }
}
