import Photos
import SwiftUI

/// 大图页：左滑下一张、右滑上一张、上滑过半移入回收站，底部固定「恢复」。
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
    /// 需求要求上滑超过屏幕高度一半才移入回收站。
    private static let discardTriggerRatio: CGFloat = 0.5

    private enum DragAxis { case horizontal, vertical }

    init(model: PhotoLibraryModel, startingAt identifier: String) {
        self.model = model
        let start = model.assets.firstIndex { $0.localIdentifier == identifier } ?? 0
        _index = State(initialValue: start)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visibleIndices, id: \.self) { i in
                    PhotoPage(asset: model.assets[i], size: geo.size)
                        .offset(
                            x: CGFloat(i - index) * geo.size.width + dragX,
                            y: i == index ? dragY : 0
                        )
                        .opacity(pageOpacity(at: i, screenHeight: geo.size.height))
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
            RestoreBar(count: model.recycleBin.count, action: restoreLatest)
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
    private var visibleIndices: [Int] {
        [index - 1, index, index + 1].filter { $0 >= 0 && $0 < model.assets.count }
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

    private func pageOpacity(at i: Int, screenHeight: CGFloat) -> Double {
        guard i == index, dragY < 0 else { return 1 }
        let progress = min(1, -dragY / (screenHeight * Self.discardTriggerRatio))
        return 1 - progress * 0.6
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if lockedAxis == nil {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    guard max(dx, dy) > Self.axisLockThreshold else { return }
                    lockedAxis = dx > dy ? .horizontal : .vertical
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
                    endVerticalDrag(translation: min(0, value.translation.height), screenHeight: size.height)
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

    private func endVerticalDrag(translation: CGFloat, screenHeight: CGFloat) {
        guard -translation > screenHeight * Self.discardTriggerRatio else {
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

private struct PhotoPage: View {

    let asset: PHAsset
    let size: CGSize

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(width: size.width, height: size.height)
        .task(id: asset.localIdentifier) {
            image = await PhotoImageProvider.fullImage(
                for: asset,
                pixelSize: CGSize(width: size.width * displayScale, height: size.height * displayScale)
            )
        }
    }
}
