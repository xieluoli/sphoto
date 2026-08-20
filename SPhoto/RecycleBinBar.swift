import SwiftUI

/// 固定在屏幕下方的回收站操作条：撤销最近一次移入，或把整个回收站提交删除。
struct RecycleBinBar: View {

    let count: Int
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onRestore) {
                Label(count > 0 ? "恢复（\(count)）" : "恢复", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }

            Divider().frame(height: 24)

            Button(role: .destructive, action: onDelete) {
                Label(count > 0 ? "删除 \(count) 张" : "删除", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.body.weight(.medium))
        .padding(.vertical, 14)
        .disabled(count == 0)
        .background(.bar)
    }
}
