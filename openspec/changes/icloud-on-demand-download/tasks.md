## 1. 取图失败判定（TDD）

- [x] 1.1 先写 `Tests/SPhotoCoreTests/PhotoRequestFailureTests.swift`，覆盖：标记取消、标记在 iCloud、取消与 iCloud 同时出现时取消优先、空字典、`info` 为 nil
- [x] 1.2 跑 `swift test` 确认红灯
- [x] 1.3 实现 `SPhoto/Core/PhotoRequestFailure.swift`，跑 `swift test` 转绿
- [x] 1.4 把新文件加进 `SPhoto.xcodeproj/project.pbxproj` 的 app target

## 2. 取图入口改造

- [x] 2.1 `PhotoImageProvider`：新增 `PhotoFetchResult`，底层请求返回它而不是 `UIImage?`
- [x] 2.2 底层请求用 `withTaskCancellationHandler` + `cancelImageRequest` 把取消传给 PhotoKit，用锁处理「回调早于 requestID 到手」的时序
- [x] 2.3 缩略图改为固定 512×512 像素、`.highQualityFormat` + `.aspectFit`、禁网；新增同步读缓存的 `cachedThumbnail(for:)`（原计划的 `.fastFormat` 实装后推翻，理由见 design 决策二）
- [x] 2.4 `fullImage` 新增 `allowsNetworkAccess` 参数，默认路径禁网
- [x] 2.5 `ThumbnailView` 适配新签名，清掉不再使用的 `displayScale`

## 3. 大图页

- [x] 3.1 `PhotoDetailView`：可见三页由 `(asset, 相对当前页的步数)` 组成，`ForEach` 的 `id` 改为 `asset.localIdentifier`，位置只用于算横向偏移
- [x] 3.2 `PhotoPage`：`init` 里同步取缓存缩略图作为 `@State image` 初值，消除首帧空白
- [x] 3.3 `PhotoPage`：加载流程改为「缩略图铺底 → 禁网探测原图 → 按结果决定是否展示下载控件」，`cancelled` 不改任何状态
- [x] 3.4 `PhotoPage`：新增 `DownloadPrompt` 状态与照片下方的下载控件（可下载 / 下载中 loading / 失败重试）
- [x] 3.5 确认上滑蒙层、提示文案、回收站操作条的行为与改动前一致（MUL-55 / MUL-56 的范围不动）

## 4. 验证

- [x] 4.1 `swift test` 全绿（15 个用例）
- [x] 4.2 `xcodebuild build` 模拟器编译通过且无新增警告
- [x] 4.3 模拟器实跑网格：29 张缩略图全部加载，`PHPhotosErrorDomain` 与 `No resource found` 均为 0 次；截图留证
- [x] 4.4 大图页交互：2026-08-28 由用户在 iPhone 16e / iOS 26.5 模拟器上手动验证通过（翻页无残留、上滑删除、首帧比例正确）。Agent 侧注入不了触摸，这一步由人操作——`simctl privacy grant photos` 写的 TCC 行 `csreq` 为 NULL，iOS 26.5 不认，授权弹窗也得人点。下载按钮属 iCloud 分支，见 4.5
- [ ] 4.5 **本环境无法验证**：iCloud 分支（`inCloud` → 下载按钮 → loading → 完成）。模拟器没有 iCloud 照片图库，只有判定逻辑被单测覆盖。需真机 + 开启「优化 iPhone 存储空间」的账号确认
