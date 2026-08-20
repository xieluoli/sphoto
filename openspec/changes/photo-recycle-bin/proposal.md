## Why

用户需要一个「只做一件事」的 iOS 相册清理工具：打开即看全部照片，进大图后用一个上滑手势把不想要的照片挪走，误操作能立刻撤回。系统相册 App 的删除流程要多次点击确认，且删掉后要进「最近删除」相册才能找回，不适合快速清理场景。

当前 `sphoto` 是空仓库，本变更交付第一个可运行版本。

## What Changes

- 新增 iOS 应用 `SPhoto`（SwiftUI，最低 iOS 17）。
- 启动时申请相册读写权限，并处理「未决定 / 已授权 / 仅选中部分 / 拒绝」四种状态。
- 网格页展示相册内全部图片的缩略图，按创建时间倒序。
- 点击缩略图进入大图页：横向滑动翻页、上滑超过屏幕高度一半移入回收站、底部固定「恢复」按钮。
- 回收站为**应用内软删除**：只在本应用隐藏照片，不调用 PhotoKit 真实删除；「恢复」把最近一张移回网格。回收站状态跨启动保留。

## Capabilities

### New Capabilities
- `photo-library-access`: 相册权限的申请、状态判定与无权限时的引导
- `photo-grid`: 全部图片的缩略图网格与数据加载
- `photo-viewer`: 大图浏览、翻页手势、上滑移入回收站手势
- `recycle-bin`: 回收站的入站、恢复、持久化与失效清理

### Modified Capabilities
无（新项目，无既有 spec）。

## Impact

- 新增代码仓 `github.com:xieluoli/sphoto`，本地路径 `/Users/xieluoli/AI_workspace/opc/sphoto`。
- 新增 Xcode 工程 `SPhoto.xcodeproj` 与应用源码目录 `SPhoto/`。
- 新增 SwiftPM 包 `SPhotoCore`，只包含回收站纯逻辑，用于在没有 Xcode 的环境下跑单元测试；应用直接编译同一批源文件，不通过包依赖引入。
- 依赖：仅系统框架 SwiftUI / Photos，无第三方依赖。
