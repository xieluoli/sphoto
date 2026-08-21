import Photos
import XCTest
@testable import SPhotoCore

final class PhotoRequestFailureTests: XCTestCase {

    func test_标记取消时判定为被取消() {
        let failure = PhotoRequestFailure(info: [PHImageCancelledKey: true])

        XCTAssertEqual(failure, .cancelled)
    }

    func test_标记在iCloud时判定为在iCloud() {
        let failure = PhotoRequestFailure(info: [PHImageResultIsInCloudKey: true])

        XCTAssertEqual(failure, .inCloud)
    }

    /// 页面划走时请求被撤销，PhotoKit 有可能同时带上「资源在 iCloud」。
    /// 这时判成 inCloud 会给一个已经不在屏幕上的页留下下载按钮，所以取消优先。
    func test_取消与在iCloud同时出现时取消优先() {
        let failure = PhotoRequestFailure(info: [
            PHImageCancelledKey: true,
            PHImageResultIsInCloudKey: true,
        ])

        XCTAssertEqual(failure, .cancelled)
    }

    func test_标记为false不算命中() {
        let failure = PhotoRequestFailure(info: [
            PHImageCancelledKey: false,
            PHImageResultIsInCloudKey: false,
        ])

        XCTAssertEqual(failure, .unavailable)
    }

    func test_空字典判定为其他不可用() {
        let failure = PhotoRequestFailure(info: [:])

        XCTAssertEqual(failure, .unavailable)
    }

    func test_没有回调信息时判定为其他不可用() {
        let failure = PhotoRequestFailure(info: nil)

        XCTAssertEqual(failure, .unavailable)
    }
}
