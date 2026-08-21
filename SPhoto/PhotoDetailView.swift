import Photos
import SwiftUI

/// 大图页：左滑下一张、右滑上一张、上滑约屏高 1/5 移入回收站，底部固定「恢复」+「删除」。
struct PhotoDetailView: View {

    let model: PhotoLibraryModel

    @Environment(\.dismiss) private var dismiss

    @State private var index: Int
    @State private var dragX: CGFloat = 0
    @State private var dragY: CGFloat = 0
    @State private var lockedAxis: DragAxis?

    /// 位移超过这个值才判定拖拽方向，避免刚落指就锁错轴。
    private static let axisLockThreshold: CGFloat = 10
    /// 横向位移超过屏宽的这个比例才翻页。
    private static let pageTriggerRatio: CGFloat = 0.25
    /// 上滑移入回收站的距离阈值，占屏幕高度的比例。
    ///
    /// 苹果没有公开「上滑要滑多远」的数值，官方给的是 WWDC18《Designing Fluid Interfaces》
    /// 的速度投影思路：拿手指抬起瞬间的速度推算它「本来会滑到哪」，再拿那个位置去判定。
    /// SwiftUI 的 `predictedEndTranslation` 就是这个投影。所以距离阈值只保留慢拖时的判定，
    /// 快速轻扫由投影提前触发，不必真的拖那么长。
    private static let discardTriggerRatio: CGFloat = 0.2
    /// 防误触底线：实际行程不到这个值一律不删，再快的轻扫也不行。
    private static let minimumDiscardTravel: CGFloat = 60
    /// 上滑丢弃时下一张最多进到屏宽的这个比例。
    ///
    /// 不封顶的话上滑够远（屏宽那么多）下一张就满屏了，待删的这张被彻底盖住——
    /// 清理 App 里这等于让人看着下一张删掉当前这张。
    private static let maxDiscardPeekRatio: CGFloat = 0.6

    private enum DragAxis { case horizontal, vertical }

    init(model: PhotoLibraryModel, startingAt identifier: String) {
        self.model = model
        let start = model.assets.firstIndex { $0.localIdentifier == identifier } ?? 0
        _index = State(initialValue: start)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visiblePages) { page in
                    PhotoPage(asset: page.asset, size: geo.size)
                        .offset(
                            x: pageOffsetX(for: page, screenWidth: geo.size.width),
                            y: page.isCurrent ? dragY : 0
                        )
                }

                discardHint(screenHeight: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture(in: geo.size))
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .background(Color.black.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            RecycleBinBar(
                count: model.recycleBin.count,
                onRestore: restoreLatest,
                onDelete: { Task { await model.deleteStaged() } }
            )
        }
        .onChange(of: model.assets.count) { _, _ in clampIndex() }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
        .tint(.primary)
        .padding()
    }

    /// 只渲染当前页和左右各一页，几千张照片也不会把视图层级撑爆。
    private var visiblePages: [VisiblePage] {
        ((index - 1)...(index + 1)).compactMap { i in
            guard model.assets.indices.contains(i) else { return nil }
            return VisiblePage(asset: model.assets[i], stepsFromCurrent: i - index)
        }
    }

    /// 横向位置。翻页时整条跟着 `dragX` 走；上滑丢弃时另算：下一张跟着上滑距离等量左移，
    /// 手指抬到阈值、提示胶囊标红那一刻，它已经进来约屏宽的四成。
    ///
    /// 这样松手硬切时，接上来的是一张眼睛已经认识的图，而不是凭空跳出来一张。
    /// 判据用 `dragY` 而不是 `lockedAxis`：`onEnded` 里 `lockedAxis` 会先被清掉，
    /// 用它会让位移不足时的回弹动画中途失效，下一张直接瞬移回屏外。
    private func pageOffsetX(for page: VisiblePage, screenWidth: CGFloat) -> CGFloat {
        let resting = CGFloat(page.stepsFromCurrent) * screenWidth + dragX
        guard page.stepsFromCurrent == 1, dragY < 0 else { return resting }
        // 封顶，别让它盖住待删的这张；两条轴不会同时有值（锁轴时另一条已归零），
        // 所以这里直接减，不必再 clamp 到 0。
        return resting - min(-dragY, screenWidth * Self.maxDiscardPeekRatio)
    }

    @ViewBuilder
    private func discardHint(screenHeight: CGFloat) -> some View {
        if lockedAxis == .vertical, dragY < 0 {
            let reached = -dragY > screenHeight * Self.discardTriggerRatio
            Text(reached ? "松手移入回收站" : "上滑移入回收站")
                .font(.callout.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(reached ? Color.red.opacity(0.9) : Color.black.opacity(0.5), in: Capsule())
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 60)
        }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if lockedAxis == nil {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    guard max(dx, dy) > Self.axisLockThreshold else { return }
                    let axis: DragAxis = dx > dy ? .horizontal : .vertical
                    // 上一段回弹可能还没走完。不清掉另一条轴的残值，两段动画会叠加进
                    // pageOffsetX，下一张会算到错误的位置上。
                    withoutAnimation {
                        if axis == .horizontal { dragY = 0 } else { dragX = 0 }
                    }
                    lockedAxis = axis
                }
                switch lockedAxis {
                case .horizontal:
                    dragX = value.translation.width
                case .vertical:
                    dragY = min(0, value.translation.height)
                case nil:
                    break
                }
            }
            .onEnded { value in
                switch lockedAxis {
                case .horizontal:
                    endHorizontalDrag(translation: value.translation.width, screenWidth: size.width)
                case .vertical:
                    endVerticalDrag(
                        translation: min(0, value.translation.height),
                        predictedTranslation: min(0, value.predictedEndTranslation.height),
                        screenHeight: size.height
                    )
                case nil:
                    break
                }
                lockedAxis = nil
            }
    }

    /// 跟系统相册一致：手指向左滑看下一张，向右滑看上一张。
    private func endHorizontalDrag(translation: CGFloat, screenWidth: CGFloat) {
        var target = index
        if abs(translation) > screenWidth * Self.pageTriggerRatio {
            target = translation < 0 ? index + 1 : index - 1
        }
        if target < 0 || target >= model.assets.count {
            target = index
        }
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
            index = target
            dragX = 0
        }
    }

    /// 慢拖看实际位移，快扫看速度投影，两者任一越线就移入回收站。
    private func endVerticalDrag(translation: CGFloat, predictedTranslation: CGFloat, screenHeight: CGFloat) {
        let travelled = -translation
        let projected = -predictedTranslation
        let threshold = screenHeight * Self.discardTriggerRatio

        guard travelled >= Self.minimumDiscardTravel, max(travelled, projected) >= threshold else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) { dragY = 0 }
            return
        }
        discardCurrent()
    }

    private func discardCurrent() {
        guard model.assets.indices.contains(index) else { return }
        let asset = model.assets[index]
        // 被移走的那张已经拖到半透明，这里直接换成下一张，不要再补一段回弹动画。
        withoutAnimation {
            model.moveToRecycleBin(asset)
            dragY = 0
            clampIndex()
        }
    }

    /// 可见列表变短后把 index 拉回合法范围；一张不剩就退回网格。
    private func clampIndex() {
        if model.assets.isEmpty {
            dismiss()
        } else if index >= model.assets.count {
            index = model.assets.count - 1
        }
    }

    private func restoreLatest() {
        guard let restored = model.restoreLatest() else { return }
        guard let restoredIndex = model.assets.firstIndex(where: { $0.localIdentifier == restored.localIdentifier }) else { return }
        // 恢复的那张可能离当前位置很远，跨页动画只会糊成一片。
        withoutAnimation { index = restoredIndex }
    }

    private func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }
}

/// 可见窗口里的一页。
///
/// 身份取资源标识而不是位置：照片被移入回收站后，位置 `i` 会换成另一张照片，
/// 用位置做身份会让 SwiftUI 把视图连同它 state 里的旧图一起复用到新照片上——
/// 屏幕上就会短暂地留着上一张。
private struct VisiblePage: Identifiable {

    let asset: PHAsset
    /// 相对当前页的页数，用来算横向偏移。
    let stepsFromCurrent: Int

    var id: String { asset.localIdentifier }

    var isCurrent: Bool { stepsFromCurrent == 0 }
}

private struct PhotoPage: View {

    let asset: PHAsset
    let size: CGSize

    @Environment(\.displayScale) private var displayScale

    @State private var image: UIImage?
    @State private var prompt: DownloadPrompt = .none
    @State private var downloadAttempt = 0

    /// 照片下方的下载控件该长什么样。
    private enum DownloadPrompt {
        /// 不需要控件：原图已在本地，或它本来就取不到
        case none
        case offer
        case downloading
        case failed
    }

    init(asset: PHAsset, size: CGSize) {
        self.asset = asset
        self.size = size
        // 从网格点进来的那张必然已在缩略图缓存里，首帧直接出图，不先闪一下转圈。
        _image = State(initialValue: PhotoImageProvider.cachedThumbnail(for: asset))
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .bottom) { downloadControl }
        .task { await loadLocalVersions() }
        // 挂在 .task 上，这一页移出可见窗口（当前页左右各一页）时下载会跟着被撤销。
        // 只翻一页时这页还在窗口里，下载继续跑——省流量是有的，但不是「一划走就停」。
        .task(id: downloadAttempt) {
            guard downloadAttempt > 0 else { return }
            await downloadFromCloud()
        }
    }

    @ViewBuilder
    private var downloadControl: some View {
        switch prompt {
        case .none:
            EmptyView()
        case .offer:
            Button { downloadAttempt += 1 } label: {
                Label("从 iCloud 下载原图", systemImage: "icloud.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 32)
        case .downloading:
            HStack(spacing: 8) {
                ProgressView().tint(.white)
                Text("正在从 iCloud 下载…")
            }
            .font(.callout)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.5), in: Capsule())
            .padding(.bottom, 32)
        case .failed:
            Button { downloadAttempt += 1 } label: {
                Label("下载失败，重试", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.bottom, 32)
        }
    }

    /// 缩略图铺底 → 禁网探测原图 → 按结果决定要不要摆下载按钮。
    private func loadLocalVersions() async {
        if image == nil { image = await PhotoImageProvider.thumbnail(for: asset) }

        switch await PhotoImageProvider.fullImage(for: asset, pixelSize: pixelSize, allowsNetworkAccess: false) {
        case .image(let full):
            image = full
        case .failure(.inCloud):
            prompt = .offer
        case .failure(.cancelled), .failure(.unavailable):
            // 划走的页别改状态；真取不到也别摆一个下不到东西的按钮
            break
        }
    }

    private func downloadFromCloud() async {
        prompt = .downloading
        switch await PhotoImageProvider.fullImage(for: asset, pixelSize: pixelSize, allowsNetworkAccess: true) {
        case .image(let full):
            image = full
            prompt = .none
        case .failure(.cancelled):
            prompt = .offer
        case .failure(.inCloud), .failure(.unavailable):
            prompt = .failed
        }
    }

    private var pixelSize: CGSize {
        CGSize(width: size.width * displayScale, height: size.height * displayScale)
    }
}
