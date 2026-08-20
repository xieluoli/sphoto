import SwiftUI

/// 固定在屏幕下方的「恢复」条，撤销最近一次移入回收站。
struct RestoreBar: View {

    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(count > 0 ? "恢复（\(count)）" : "恢复", systemImage: "arrow.uturn.backward")
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .disabled(count == 0)
        .background(.bar)
    }
}
