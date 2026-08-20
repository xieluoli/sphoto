# SPhoto

极简 iOS 相册清理工具：打开看全部照片，进大图后上滑把不要的挪进回收站，误删随手恢复。

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

**回收站是应用内软删除**：只在本应用隐藏，系统相册里的原图不会被删除，也不会释放存储空间。

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
swift test          # 需要 Xcode 提供 XCTest
```
