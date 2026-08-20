## Why

用户需要一个「只做一件事」的 iOS 相册清理工具：打开即看全部照片，进大图后用一个上滑手势把不想要的照片挪走，误操作能立刻撤回。系统相册 App 删一张要点好几次，不适合连续快速清理。

当前 `sphoto` 是空仓库，本变更交付第一个可运行版本。

## What Changes

- 新增 iOS 应用 `SPhoto`（SwiftUI，最低 iOS 17）。
- 启动时申请相册读写权限，并处理「未决定 / 已授权 / 仅选中部分 / 拒绝」四种状态。
- 网格页展示相册内全部图片的缩略图，按创建时间倒序。
- 点击缩略图进入大图页：横向滑动翻页、上滑超过屏幕高度一半移入待删暂存区、底部固定操作条。
- **删除分两段**：
  - **暂存**——上滑只在应用内隐藏并记入暂存区，不碰系统相册；底部「恢复」按后进先出撤销。暂存区跨启动保留。
  - **提交**——底部「删除 N 张」一次性调用 `PHAssetChangeRequest.deleteAssets`，把暂存的全部照片移入系统相册的「最近删除」，系统只弹一次确认框。提交成功后暂存区清空；用户在确认框点取消则暂存区原样保留。
- 提交后照片由系统「最近删除」保管 30 天，应用内不再提供恢复入口——PhotoKit 没有开放任何 API 让第三方 App 列出或恢复「最近删除」的内容。

## Capabilities

### New Capabilities
- `photo-library-access`: 相册权限的申请、状态判定与无权限时的引导
- `photo-grid`: 全部图片的缩略图网格与数据加载
- `photo-viewer`: 大图浏览、翻页手势、上滑移入暂存区手势
- `recycle-bin`: 待删暂存区的入站、恢复、持久化、失效清理与提交删除

### Modified Capabilities
无（新项目，无既有 spec）。

## Impact

- 新增代码仓 `github.com:xieluoli/sphoto`，本地路径 `/Users/xieluoli/AI_workspace/opc/sphoto`。
- 新增 Xcode 工程 `SPhoto.xcodeproj` 与应用源码目录 `SPhoto/`。
- 新增 SwiftPM 包 `SPhotoCore`，只包含暂存区纯逻辑，用于在没有 Xcode 的环境下跑单元测试；应用直接编译同一批源文件，不通过包依赖引入。
- 依赖：仅系统框架 SwiftUI / Photos，无第三方依赖。
