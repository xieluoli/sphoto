## Context

三个现象（进大图页要等、下载中翻页卡顿、翻页后仍显示上一张）在现有代码里对应三个独立根因，改一个不会连带修好另外两个。

**根因一：无条件联网取原图。** `PhotoImageProvider.requestImage` 把 `isNetworkAccessAllowed = true` 写死，缩略图和原图共用。于是滚网格会批量下载，进大图页会下当前页和左右各一页的原图。

**根因二：任务取消传不到 PhotoKit。** `withCheckedContinuation` 只把回调包成 `async`，`.task(id:)` 在视图移除时取消的是 Swift Task，PhotoKit 那边的请求还在跑。快速连翻会在 PhotoKit 队列里堆一串几秒级的网络请求，当前页的请求排在它们后面——这才是「滑动卡顿」的直接来源。

**根因三：视图身份绑在位置上。** `ForEach(visibleIndices, id: \.self)` 用 `Int` 位置做身份，`PhotoPage` 的 `@State image` 跟着位置走。照片移入回收站后 `model.assets` 整体前移，位置 `i` 换成了另一张照片，但 SwiftUI 认为身份没变，复用同一个 `PhotoPage` 实例连同它 state 里的旧图；`.task(id:)` 重新请求要等异步返回，这段窗口期屏幕上就是上一张。

约束：只用系统框架；不引入第三方依赖；不动手势阈值和回收站逻辑。

部署目标本条设计成文时是 iOS 17，同一提交里 MUL-56 为了用原生 Liquid Glass 已提到 26.0。本设计不依赖任何 iOS 17 独有行为，结论不受影响。

## Goals / Non-Goals

**Goals**
- iCloud 照片默认停在缩略图，下不下原图由用户点按钮决定。
- 翻页立刻响应，划走的页不再拖累当前页。
- 任一时刻屏幕上的图属于当下这张照片。

**Non-Goals**
- 不做下载百分比进度条。需求只要求「有 loading」，转圈足够，接 `progressHandler` 要把回调从任意队列搬回主线程，代价大于收益。
- 不做批量预下载、离线队列、后台续传。
- 不碰上滑蒙层与连续删除闪烁（MUL-55 的范围），不碰底部操作条样式（MUL-56 的范围）。
- 不优化网格滚动性能，本次只把网格的联网开关关掉。

## Decisions

### 决策一：用「禁网请求 + 读 info 字典」探测原图在不在本地

PhotoKit 没有公开「这张在不在本地」的属性。业界另一条路是 `PHAssetResource` 的 `locallyAvailable` ——那是私有 KVC，上架有风险，排除。

官方路径是：发一个 `isNetworkAccessAllowed = false` 的请求，若资源只在云端，回调会给 `image == nil` 且 `info[PHImageResultIsInCloudKey] == true`。这条路顺带把探测和取图合成了一次请求：原图在本地就直接拿到图，不在就拿到「在 iCloud」的信号。

### 决策二：缩略图与原图都用 `.highQualityFormat`，都单次回调

`.opportunistic` 会多次回调，配 `withCheckedContinuation` 会重复 resume 直接崩溃。`.fastFormat` 与 `.highQualityFormat` 都保证只回调一次。

缩略图原本选的是 `.fastFormat`——语义看着最贴「给我本地最快能拿到的版本」。**实装后推翻了**：它只肯从已经生成好的低清资源里挑，没有就直接报 `PHPhotosErrorDomain 3303`，不会退回去解码原图，刚导入还没生成缩略图的照片会整格空着（模拟器实测 29 张全空）。

- 缩略图 `.highQualityFormat` + 禁网 + `.aspectFit`：必要时自己解码，不会空格。禁网才是「不自动下载」的落点，deliveryMode 不是。
  用 `aspectFit` 而不是 `aspectFill`：配 `resizeMode = .exact` 时 `aspectFill` 会把图裁成正方形，大图页拿它铺首帧会缺掉两侧且比例不对；网格自己 `scaledToFill` + `clipped` 到方格，拿未裁切的图裁出来结果一样。
- 原图 `.highQualityFormat` + 禁网：探测兼取图，见决策一。
- 用户点下载：同样 `.highQualityFormat`，但允许联网。

缩略图尺寸从「调用方传入」改为固定 512×512 像素。原来网格传的是格子尺寸、大图页若也调它会传全屏尺寸，而缓存键只有资源标识不含尺寸——两边混用会把全屏图塞进缩略图缓存，400 张就是几百 MB。固定尺寸后缓存语义才是一致的，同时 512 像素既够铺 3 列网格，也够当大图页的过渡底图。

### 决策三：取消要真的传给 PhotoKit

`withTaskCancellationHandler` 包住请求，取消时调 `PHImageManager.cancelImageRequest(requestID)`。

有个时序坑：缓存命中时 `requestImage` 的回调可能在函数返回**之前**同步触发，此时 requestID 还没拿到手。所以用一把锁把「存 ID」和「取消」串起来，并记住「已经取消过」——若取消发生在存 ID 之前，等 ID 到手立刻取消它。

被取消的请求，PhotoKit 会回调一次并在 info 里标 `PHImageCancelledKey`。这一条必须与「资源在 iCloud」区分开，且优先级更高：一个划走的页不该留下一个「点我下载」的按钮。

### 决策四：页身份改用资源标识

`ForEach` 的 `id` 从位置改为 `asset.localIdentifier`，位置只留给计算横向偏移。照片在列表里前移时，视图跟着这张照片走，它 state 里的图始终是自己的图。这一条同时消掉了「删除后残留上一张」和「快速连翻残留上一张」。

配套：`PhotoPage` 在 `init` 里用**同步**读缓存的方式给 `@State image` 初值。从网格点进来的那张必然已在缓存中，首帧就有图，不再先闪一下转圈。

### 决策五：`PhotoRequestFailure` 放进 `SPhoto/Core/`

`info` 字典的判定是本次唯一有分支、有优先级、且不依赖 UI 的逻辑，正好落在既有的 `SPhotoCore` 包里，可以用 `swift test` 覆盖。其余（SwiftUI 的视图身份、请求取消）没有能在无 UI 环境验证的接缝，靠模拟器实跑与代码审查。

## 数据模型 / 接口契约

```swift
// SPhoto/Core/PhotoRequestFailure.swift —— 纯逻辑，进 SPhotoCore，可单测
public enum PhotoRequestFailure: Equatable {
    case cancelled      // 请求被撤销（优先级最高）
    case inCloud        // 原图只在 iCloud，本次请求不允许联网
    case unavailable    // 其他取不到

    public init(info: [AnyHashable: Any]?)
}

// SPhoto/PhotoImageProvider.swift
enum PhotoFetchResult {
    case image(UIImage)
    case failure(PhotoRequestFailure)
}

enum PhotoImageProvider {
    /// 本地缩略图，固定 512×512 像素，带缓存，永不联网
    static func cachedThumbnail(for asset: PHAsset) -> UIImage?     // 同步读缓存，供首帧使用
    static func thumbnail(for asset: PHAsset) async -> UIImage?

    /// 全屏原图。allowsNetworkAccess=false 时用于探测，不会下载
    static func fullImage(for asset: PHAsset, pixelSize: CGSize, allowsNetworkAccess: Bool) async -> PhotoFetchResult
}

// SPhoto/PhotoDetailView.swift 内部
private enum DownloadPrompt: Equatable {
    case none           // 不需要控件
    case offer          // 展示「从 iCloud 下载原图」
    case downloading    // 展示 loading
    case failed         // 展示「重试」
}
```

无持久化变更，无网络接口，`UserDefaults` 的键不变。

## Risks & Mitigations

| 风险 | 应对 |
|---|---|
| **iCloud 场景无法在模拟器复现。** 模拟器没有 iCloud 照片图库，`inCloud` 分支、下载按钮、下载 loading 三条路径跑不到 | 判定逻辑用单测锁死；UI 路径需真机 + 开启「优化 iPhone 存储空间」的账号验证，交付时明确标为待用户确认 |
| 禁网让网格里的 iCloud 照片比原来糊 | 这是需求的直接后果，不是缺陷；在 proposal 的 Impact 里写明，交付时也向用户点出 |
| 取消请求引入双重 resume 崩溃 | `cancelImageRequest` 只会让 PhotoKit 回调一次（带 cancelled 标记），continuation 仍只 resume 一次；锁只保护 requestID 的读写，不包住 continuation |
| 下载中翻页会中断下载，用户可能期望后台续传 | 按「移出可见窗口即撤销」处理，不消耗后台流量；回到该页时按钮回到可下载状态。注意只翻一页时该页仍在窗口内（当前页左右各一页），下载继续跑 |

回滚：全部改动集中在三个视图/工具文件加一个新 Core 文件，`git revert` 单个提交即可回到 0.0.2 行为。

## Open Questions

- 网格里 iCloud 照片变糊，用户是否接受？若不接受，备选是给网格单独放开联网但加并发上限——本次不做，等反馈。
