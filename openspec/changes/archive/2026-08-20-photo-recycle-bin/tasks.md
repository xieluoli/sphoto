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
- [x] 4.3 `SPhoto/RestoreBar.swift`：底部固定「恢复」条，空回收站时禁用（6.4 起改名为 `RecycleBinBar.swift`，加「删除 N 张」）
- [x] 4.4 `SPhoto/PhotoDetailView.swift`：三页窗口渲染、轴锁定手势、左滑下一张/右滑上一张（跟随系统相册）、上滑过半移入回收站、跟手反馈与阈值提示、恢复后跳转

## 5. 验证

- [x] 5.1 `swift test` 全绿（7 个用例）
- [x] 5.2 `plutil -lint` 校验 `project.pbxproj`；脚本校验 pbxproj 内所有文件引用在磁盘上存在、所有 UUID 引用有定义
- [x] 5.3 `swiftc -parse` 逐个源文件校验语法
- [x] 5.4 装 Xcode 16.1 后 `xcodebuild` 编译通过，修掉暴露出的 2 个编译错误；模拟器 runtime 未装，实机交互仍未验

## 6. 提交删除到系统「最近删除」（2026-08-20 需求修正）

用户澄清：删除必须最终落到系统相册的「最近删除」。原「纯应用内软删除」改为两段式，见 design 决策 1。

- [x] 6.1 把新 spec 的两个场景（确认删除→清空、取消→原样保留）写成测试。**一次就绿，不是红灯**：这两条行为由既有的 `prune(keepingOnly:)` 完全覆盖（该方法在 `bc4914f` 就存在并已有测试），本次改动的纯逻辑层没有新增行为
- [x] 6.2 因此不新增 `RecycleBin.clear()` —— 删除成功后 `reload()` 重新拉取相册，`prune` 自动清掉已删资源，再加一个清空方法是重复机制
- [x] 6.3 `PhotoLibraryModel.deleteStaged()`：把暂存区里的资源一次性交给 `PHAssetChangeRequest.deleteAssets`；成功则清空暂存区并重载，用户取消（`PHPhotosError.userCancelled`）则原样保留
- [x] 6.4 `SPhoto/RestoreBar.swift` 改名 `RecycleBinBar.swift`：底部条改为「恢复」+「删除 N 张」两个按钮，回收站为空时两个都禁用；同步改 `project.pbxproj` 的 4 处引用
- [x] 6.5 `PhotoGridView` / `PhotoDetailView` 接上新底部条与提交动作
- [x] 6.6 更新 `README.md` 的删除语义描述
- [x] 6.7 验证（部分）：`swift test` 9 绿、`xcodebuild` Debug + Release 均 BUILD SUCCEEDED、pbxproj 编译列表与磁盘一致、`jy-openspec validate --strict` 通过
- [x] 6.8 **人工已验（2026-08-20 用户确认「通了」）**：模拟器实跑走一遍「上滑暂存 → 恢复 → 删除 N 张 → 系统确认框 → 照片进系统『最近删除』/ 点取消回收站原样保留」。命令行注入不了触摸（辅助功能未授权），这一段只能手验
