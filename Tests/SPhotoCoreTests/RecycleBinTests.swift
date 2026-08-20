import XCTest
@testable import SPhotoCore

final class RecycleBinTests: XCTestCase {

    func test_移入回收站后被记录() {
        var bin = RecycleBin()
        bin.add("A")

        XCTAssertEqual(bin.identifiers, ["A"])
        XCTAssertEqual(bin.count, 1)
        XCTAssertFalse(bin.isEmpty)
    }

    func test_重复移入不产生重复记录且顺序更新为最近() {
        var bin = RecycleBin()
        bin.add("A")
        bin.add("B")
        bin.add("A")

        XCTAssertEqual(bin.identifiers, ["B", "A"])
    }

    func test_恢复按后进先出() {
        var bin = RecycleBin()
        bin.add("A")
        bin.add("B")
        bin.add("C")

        XCTAssertEqual(bin.restoreLatest(), "C")
        XCTAssertEqual(bin.restoreLatest(), "B")
        XCTAssertEqual(bin.identifiers, ["A"])
    }

    func test_恢复后不再属于回收站() {
        var bin = RecycleBin()
        bin.add("A")
        _ = bin.restoreLatest()

        XCTAssertTrue(bin.isEmpty)
        XCTAssertEqual(bin.identifiers, [])
    }

    func test_空回收站恢复返回nil() {
        var bin = RecycleBin()

        XCTAssertNil(bin.restoreLatest())
        XCTAssertTrue(bin.isEmpty)
    }

    func test_清理已不存在的资源且保留其余顺序() {
        var bin = RecycleBin()
        bin.add("A")
        bin.add("B")
        bin.add("C")

        bin.prune(keepingOnly: ["C", "A"])

        XCTAssertEqual(bin.identifiers, ["A", "C"])
    }

    func test_清理后恢复顺序仍是后进先出() {
        var bin = RecycleBin(identifiers: ["A", "B", "C"])

        bin.prune(keepingOnly: ["A", "B"])

        XCTAssertEqual(bin.restoreLatest(), "B")
        XCTAssertEqual(bin.restoreLatest(), "A")
        XCTAssertNil(bin.restoreLatest())
    }

    // spec: recycle-bin「用户确认删除 → 回收站清空」
    func test_提交删除后这些资源已不在相册回收站被清空() {
        var bin = RecycleBin()
        bin.add("A")
        bin.add("B")

        // 提交删除成功后重新拉取相册，A/B 已进系统「最近删除」，不再出现在可见资源里
        bin.prune(keepingOnly: ["C"])

        XCTAssertTrue(bin.isEmpty)
        XCTAssertNil(bin.restoreLatest())
    }

    // spec: recycle-bin「用户取消删除 → 回收站原样保留」
    func test_取消删除后回收站原样保留() {
        var bin = RecycleBin()
        bin.add("A")
        bin.add("B")

        // 用户在系统确认框点了取消，相册没有变化
        bin.prune(keepingOnly: ["A", "B", "C"])

        XCTAssertEqual(bin.identifiers, ["A", "B"])
        XCTAssertEqual(bin.restoreLatest(), "B")
    }
}
