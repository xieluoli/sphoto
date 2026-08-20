import Photos
import UIKit

/// 按需向 PhotoKit 取图。缩略图会缓存，避免网格来回滚动时反复解码。
enum PhotoImageProvider {

    private static let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 400
        return cache
    }()

    static func thumbnail(for asset: PHAsset, pixelSize: CGSize) async -> UIImage? {
        let key = asset.localIdentifier as NSString
        if let cached = thumbnailCache.object(forKey: key) { return cached }

        let image = await requestImage(for: asset, pixelSize: pixelSize, contentMode: .aspectFill)
        if let image { thumbnailCache.setObject(image, forKey: key) }
        return image
    }

    static func fullImage(for asset: PHAsset, pixelSize: CGSize) async -> UIImage? {
        await requestImage(for: asset, pixelSize: pixelSize, contentMode: .aspectFit)
    }

    private static func requestImage(
        for asset: PHAsset,
        pixelSize: CGSize,
        contentMode: PHImageContentMode
    ) async -> UIImage? {
        let options = PHImageRequestOptions()
        // highQualityFormat 保证回调只走一次，配合 continuation 才安全。
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: pixelSize,
                contentMode: contentMode,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
