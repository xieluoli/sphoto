import Photos
import UIKit

/// 一次取图的结果。取不到图时必须知道原因，界面才能决定是「摆个下载按钮」还是「什么都别做」。
enum PhotoFetchResult {
    case image(UIImage)
    case failure(PhotoRequestFailure)
}

/// 按需向 PhotoKit 取图。两条原则：
///
/// 1. **缩略图永不联网。** iCloud 照片图库在本地始终保留缩略图，取本地版本就够铺满网格；
///    为了一个格子去下几 MB 原图，既慢又费流量。
/// 2. **原图默认也不联网。** 先禁网探测它在不在本地，只有用户明确点了下载按钮才允许联网。
enum PhotoImageProvider {

    /// 缩略图统一按这个像素尺寸取，网格和大图页的首帧共用一份缓存。
    /// 缓存键只有资源标识、不含尺寸，尺寸若由调用方决定，全屏图会被塞进缩略图缓存。
    private static let thumbnailPixelSize = CGSize(width: 512, height: 512)

    private static let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // 主要按字节封顶：缩略图尺寸固定，按张数封顶会随机型浮动好几倍
        // ——同样 400 张，小屏机和大屏机占用差出三四倍。
        cache.totalCostLimit = 64 * 1024 * 1024
        // 再留一道张数上限：cost 是从 cgImage 算的，取不到时记 0，那张图就完全不计入
        // totalCostLimit。只靠字节封顶的话这种图能把缓存撑到没有上限。
        cache.countLimit = 400
        return cache
    }()

    /// 同步读缓存。大图页首帧用它，避免从网格点进来时先闪一下空白。
    static func cachedThumbnail(for asset: PHAsset) -> UIImage? {
        thumbnailCache.object(forKey: asset.localIdentifier as NSString)
    }

    static func thumbnail(for asset: PHAsset) async -> UIImage? {
        if let cached = cachedThumbnail(for: asset) { return cached }

        let options = PHImageRequestOptions()
        // 不能用 fastFormat：它只肯从已经生成好的低清资源里挑，没有就直接报
        // PHPhotosErrorDomain 3303，而不会退回去解码原图——刚导入、还没来得及生成缩略图的
        // 照片会整格空着。highQualityFormat 同样只回调一次，且必要时会自己解码。
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        // 禁网是这次的重点：iCloud 上的照片只用本地已有的版本，不为一个格子去下几 MB 原图。
        options.isNetworkAccessAllowed = false

        // 必须 aspectFit：aspectFill + exact 会把图裁成正方形，大图页拿它铺首帧时
        // 非方形照片会缺掉两侧、比例也不对，等原图回来再跳一次。
        // 网格那边自己 scaledToFill + clipped 到方格，拿未裁切的图裁出来结果一样。
        guard case let .image(image) = await request(
            asset: asset,
            pixelSize: thumbnailPixelSize,
            contentMode: .aspectFit,
            options: options
        ) else { return nil }

        let bytes = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        thumbnailCache.setObject(image, forKey: asset.localIdentifier as NSString, cost: bytes)
        return image
    }

    /// 取全屏原图。
    ///
    /// `allowsNetworkAccess` 为 false 时兼作探测：原图在本地就直接拿到图，只在 iCloud 则返回
    /// `.failure(.inCloud)`，而不会默默把它下下来。
    static func fullImage(
        for asset: PHAsset,
        pixelSize: CGSize,
        allowsNetworkAccess: Bool
    ) async -> PhotoFetchResult {
        let options = PHImageRequestOptions()
        // highQualityFormat 保证回调只走一次，配合 continuation 才安全。
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = allowsNetworkAccess

        return await request(
            asset: asset,
            pixelSize: pixelSize,
            contentMode: .aspectFit,
            options: options
        )
    }

    /// 把 PhotoKit 的回调包成 async，并把 Swift 的任务取消真正传给 PhotoKit。
    ///
    /// 只取消 Task 不会停掉已经发出的请求：快速连翻时它们会堆在 PhotoKit 队列里，
    /// 当前页的取图排在后面，表现出来就是滑动卡顿。
    private static func request(
        asset: PHAsset,
        pixelSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions
    ) async -> PhotoFetchResult {
        let handle = RequestHandle()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let id = PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: pixelSize,
                    contentMode: contentMode,
                    options: options
                ) { image, info in
                    if let image {
                        continuation.resume(returning: .image(image))
                    } else {
                        continuation.resume(returning: .failure(PhotoRequestFailure(info: info)))
                    }
                }
                handle.store(id)
            }
        } onCancel: {
            handle.cancel()
        }
    }
}

/// 保管一次请求的 ID，好在任务取消时撤销它。
///
/// 缓存命中时 `requestImage` 的回调会在函数返回**之前**同步触发，那一刻 ID 还没到手；
/// 取消也可能早于 ID 到手。所以两边都过同一把锁，并记住「已经取消过」。
private final class RequestHandle: @unchecked Sendable {

    private let lock = NSLock()
    private var id: PHImageRequestID?
    private var isCancelled = false

    func store(_ id: PHImageRequestID) {
        lock.lock()
        defer { lock.unlock() }
        if isCancelled {
            PHImageManager.default().cancelImageRequest(id)
        } else {
            self.id = id
        }
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
        if let id { PHImageManager.default().cancelImageRequest(id) }
        id = nil
    }
}
