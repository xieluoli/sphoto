# SPhoto

极简 iOS 相册清理工具：打开看全部照片，进大图后上滑把不要的挪进回收站，误删随手恢复，攒够了一次性删进系统相册的「最近删除」。

## 跑起来

```bash
open SPhoto.xcodeproj      # 需要 Xcode 15+，部署目标 iOS 17
```

选一个模拟器或真机直接运行。首次启动会申请相册权限。

## 交互

| 操作 | 结果 |
|---|---|
| 点缩略图 | 进大图 |
| 左滑 | 下一张 |
| 右滑 | 上一张 |
| 上滑超过屏幕一半 | 当前图片移入回收站 |
| 底部「恢复」 | 撤销最近一次移入，后进先出 |
| 底部「删除 N 张」 | 把回收站里的全部照片一次性移入系统相册「最近删除」 |

**删除分两段**：

1. **暂存**——上滑只在本应用内隐藏，系统相册里的原图不动，随时可以「恢复」。回收站跨启动保留。
2. **提交**——点「删除 N 张」，一次 `PHAssetChangeRequest.deleteAssets` 把回收站里的全部照片交给系统，只弹一次确认框，之后它们进入系统相册的「最近删除」。取消则回收站原样保留。

提交后应用内不再提供恢复入口：PhotoKit 没有开放任何 API 让第三方 App 列出或恢复「最近删除」的内容。要找回请去系统「照片 → 最近删除」，系统保留 30 天。

## 目录

```
SPhoto/            App 源码（SwiftUI）
  Core/            纯逻辑，不依赖 UIKit / PhotoKit
Tests/             SPhotoCore 单元测试
Package.swift      只为在没有 Xcode 的环境跑纯逻辑测试，App 不依赖它
openspec/          需求与设计，见 changes/photo-recycle-bin/
```

需求、设计决策与取舍：[openspec/changes/photo-recycle-bin/](openspec/changes/photo-recycle-bin/)
（[proposal](openspec/changes/photo-recycle-bin/proposal.md) ·
[design](openspec/changes/photo-recycle-bin/design.md) ·
[tasks](openspec/changes/photo-recycle-bin/tasks.md)）

## 测试

```bash
swift test                                            # 回收站逻辑，9 个用例
xcodebuild -project SPhoto.xcodeproj -target SPhoto \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build  # 编译整个 App
```
