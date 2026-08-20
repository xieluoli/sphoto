import Foundation
import Photos

/// 相册数据源：授权状态、可见图片列表、回收站。
///
/// `assets` 已经过滤掉回收站里的图片，界面直接用它即可。
@MainActor
@Observable
final class PhotoLibraryModel {

    private static let recycleBinKey = "recycleBin.identifiers"

    private(set) var authorization: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    /// 当前可见的图片，按创建时间倒序。
    private(set) var assets: [PHAsset] = []

    private(set) var recycleBin: RecycleBin

    private var allAssets: [PHAsset] = []
    private var changeObserver: LibraryChangeObserver?

    init() {
        recycleBin = RecycleBin(identifiers: UserDefaults.standard.stringArray(forKey: Self.recycleBinKey) ?? [])
    }

    /// 应用启动时调用：未决定就弹系统授权弹窗，拿到权限后加载图片。
    func start() async {
        if authorization == .notDetermined {
            authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard canReadLibrary else { return }
        startObservingLibrary()
        await reload()
    }

    /// 从系统设置改完权限回到前台时调用。
    func refreshAuthorization() async {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard current != authorization else { return }
        authorization = current
        guard canReadLibrary else {
            allAssets = []
            assets = []
            return
        }
        startObservingLibrary()
        await reload()
    }

    func moveToRecycleBin(_ asset: PHAsset) {
        recycleBin.add(asset.localIdentifier)
        persistRecycleBin()
        refreshVisibleAssets()
    }

    /// 撤销最近一次移入回收站，返回被恢复的图片；回收站为空时返回 nil。
    @discardableResult
    func restoreLatest() -> PHAsset? {
        guard let identifier = recycleBin.restoreLatest() else { return nil }
        persistRecycleBin()
        refreshVisibleAssets()
        return allAssets.first { $0.localIdentifier == identifier }
    }

    /// 把回收站里的照片一次性移入系统相册的「最近删除」。
    ///
    /// 系统只弹一次确认框。用户取消时回收站原样保留——删除没发生，不需要额外处理。
    /// 删除成功后重新拉取相册，已删资源不再返回，`reload` 里的 `prune` 会把回收站清空。
    func deleteStaged() async {
        let staged = Set(recycleBin.identifiers)
        let assets = allAssets.filter { staged.contains($0.localIdentifier) }
        guard !assets.isEmpty else { return }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }
            await reload()
        } catch {
            // 用户在系统确认框点了取消，回收站原样保留
        }
    }

    private var canReadLibrary: Bool {
        authorization == .authorized || authorization == .limited
    }

    private func reload() async {
        allAssets = await Task.detached(priority: .userInitiated) { Self.fetchImageAssets() }.value
        recycleBin.prune(keepingOnly: Set(allAssets.map(\.localIdentifier)))
        persistRecycleBin()
        refreshVisibleAssets()
    }

    private func refreshVisibleAssets() {
        let binned = Set(recycleBin.identifiers)
        assets = allAssets.filter { !binned.contains($0.localIdentifier) }
    }

    private func persistRecycleBin() {
        UserDefaults.standard.set(recycleBin.identifiers, forKey: Self.recycleBinKey)
    }

    private func startObservingLibrary() {
        guard changeObserver == nil else { return }
        let observer = LibraryChangeObserver { [weak self] in
            Task { @MainActor in await self?.reload() }
        }
        PHPhotoLibrary.shared().register(observer)
        changeObserver = observer
    }

    private nonisolated static func fetchImageAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)

        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }
}

/// PhotoKit 的变更回调要求一个 NSObject，这里只做转发。
private final class LibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver {

    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        onChange()
    }
}
