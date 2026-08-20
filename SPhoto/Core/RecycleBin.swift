import Foundation

/// 应用内回收站：只记录被移入的相册资源标识，系统相册里的原图不会被删除。
///
/// `identifiers` 按移入先后排列，最后一个是最近移入的那张，恢复时后进先出。
public struct RecycleBin: Equatable {

    public private(set) var identifiers: [String]

    public init(identifiers: [String] = []) {
        self.identifiers = identifiers
    }

    public var isEmpty: Bool { identifiers.isEmpty }

    public var count: Int { identifiers.count }

    /// 移入回收站。已经在回收站里的资源不重复记录，只把它的顺序提到最近。
    public mutating func add(_ identifier: String) {
        identifiers.removeAll { $0 == identifier }
        identifiers.append(identifier)
    }

    /// 撤销最近一次移入，返回被恢复的资源标识；回收站为空时返回 nil。
    public mutating func restoreLatest() -> String? {
        identifiers.popLast()
    }

    /// 丢弃已经不在相册里的记录，保留其余记录的先后顺序。
    public mutating func prune(keepingOnly existing: Set<String>) {
        identifiers.removeAll { !existing.contains($0) }
    }
}
