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
}
