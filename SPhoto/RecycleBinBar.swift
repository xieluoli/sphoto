import SwiftUI

/// 悬浮在屏幕下方的回收站操作条：撤销最近一次移入，或把整个回收站提交删除。
///
/// 视觉走 iOS 26 的 Liquid Glass：四周留边不贴屏幕、胶囊圆角，材质、边缘高光与投影
/// 全部由 `.glassEffect()` 提供，下方内容透出、模糊并随滚动折射。
struct RecycleBinBar: View {

    let count: Int
    let onRestore: () -> Void
    let onDelete: () -> Void

    /// 操作条与屏幕左右边缘的间距，也是「悬浮」最直观的那一点。
    private static let screenInset: CGFloat = 16
    /// 与底部安全区之间再垫一层，避免贴着 home indicator。
    private static let bottomInset: CGFloat = 10

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onRestore) {
                Label(count > 0 ? "恢复（\(count)）" : "恢复", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }

            // 玻璃本身不画分隔线，这里自己描一条，保证两个按钮的点击边界在视觉上分得开。
            Capsule()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 22)

            Button(role: .destructive, action: onDelete) {
                Label(count > 0 ? "删除 \(count) 张" : "删除", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.body.weight(.medium))
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .glassEffect(.regular, in: .capsule)
        .disabled(count == 0)
        .padding(.horizontal, Self.screenInset)
        .padding(.bottom, Self.bottomInset)
    }
}
