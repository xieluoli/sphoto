import Photos

/// 没拿到图时，PhotoKit 通过回调的 `info` 字典说明原因。这里把散落在字典里的标记翻译成一个结论。
///
/// 取消的优先级最高：页面划走时请求会被撤销，而 PhotoKit 有可能同时带上「资源在 iCloud」。
/// 若判成 `inCloud`，就会给一个已经不在屏幕上的页留下下载按钮。
public enum PhotoRequestFailure: Equatable {

    /// 请求被撤销，界面不应据此改变任何状态
    case cancelled
    /// 原图只在 iCloud，而本次请求不允许联网
    case inCloud
    /// 其他取不到的情况：出错、资源已删除
    case unavailable

    public init(info: [AnyHashable: Any]?) {
        if info?[PHImageCancelledKey] as? Bool == true {
            self = .cancelled
        } else if info?[PHImageResultIsInCloudKey] as? Bool == true {
            self = .inCloud
        } else {
            self = .unavailable
        }
    }
}
