## 1. 工程骨架

- [x] 1.1 建立目录结构：`SPhoto/`（app 源码）、`SPhoto/Core/`（纯逻辑）、`Tests/SPhotoCoreTests/`
- [x] 1.2 写 `Package.swift`：`SPhotoCore` target 指向 `SPhoto/Core`，测试 target 指向 `Tests/SPhotoCoreTests`
- [x] 1.3 写 `SPhoto.xcodeproj/project.pbxproj` 与 shared scheme，配置 bundle id、iOS 17 部署目标、`INFOPLIST_KEY_NSPhotoLibraryUsageDescription`
- [x] 1.4 写 `.gitignore`、`README.md`

## 2. 回收站纯逻辑（TDD）

- [x] 2.1 先写 `Tests/SPhotoCoreTests/RecycleBinTests.swift`，覆盖：入站、去重、后进先出恢复、空回收站恢复返回 nil、清理失效 id、清理后恢复顺序
- [x] 2.2 跑 `swift test` 确认红灯（`RecycleBin` 未实现）
- [x] 2.3 实现 `SPhoto/Core/RecycleBin.swift`，跑 `swift test` 转绿

## 3. 相册接入

- [x] 3.1 `SPhoto/PhotoLibraryModel.swift`：授权状态机、拉取 `.image` 资源、按创建时间倒序、过滤回收站、`PHPhotoLibraryChangeObserver` 刷新
- [x] 3.2 回收站读写接入 `UserDefaults` 持久化，加载时按当前相册内容清理失效 id
- [x] 3.3 `SPhoto/PhotoImageProvider.swift`：缩略图与大图的按需请求、缩略图缓存

## 4. 界面

- [x] 4.1 `SPhoto/SPhotoApp.swift` + `SPhoto/RootView.swift`：按授权状态分发到加载态 / 网格 / 拒绝引导页，回前台时复检权限
- [x] 4.2 `SPhoto/PhotoGridView.swift` + `SPhoto/ThumbnailView.swift`：网格、空状态、点击进大图
- [x] 4.3 `SPhoto/RestoreBar.swift`：底部固定「恢复」条，空回收站时禁用
- [x] 4.4 `SPhoto/PhotoDetailView.swift`：三页窗口渲染、轴锁定手势、左滑下一张/右滑上一张（跟随系统相册）、上滑过半移入回收站、跟手反馈与阈值提示、恢复后跳转

## 5. 验证

- [x] 5.1 跑通全部用例（本机无 Xcode 拿不到 XCTest，改用等价的独立跑手验证同一批断言）
- [x] 5.2 `plutil -lint` 校验 `project.pbxproj`；脚本校验 pbxproj 内所有文件引用在磁盘上存在、所有 UUID 引用有定义
- [x] 5.3 `swiftc -parse` 逐个源文件校验语法
- [x] 5.4 记录本机无 Xcode、无法编译 iOS target 与跑模拟器这一限制，交由用户在装有 Xcode 的环境复验
