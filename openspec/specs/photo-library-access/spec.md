# photo-library-access Specification

## Purpose
TBD - created by archiving change photo-recycle-bin. Update Purpose after archive.

## Requirements

### Requirement: 启动时申请相册权限
应用启动后必须主动向系统申请相册的读写权限（`PHAccessLevel.readWrite`），并根据授权结果决定展示内容。

#### Scenario: 首次启动尚未决定
- **WHEN** 应用启动且相册授权状态为 `notDetermined`
- **THEN** 弹出系统权限申请弹窗，弹窗期间界面展示加载态而非空相册

#### Scenario: 用户授予完全访问
- **WHEN** 授权状态为 `authorized`
- **THEN** 进入缩略图网格页并加载相册内全部图片

#### Scenario: 用户只选择部分照片
- **WHEN** 授权状态为 `limited`
- **THEN** 进入缩略图网格页，只展示用户已选中的图片，并提供入口让用户追加选择

#### Scenario: 用户拒绝授权
- **WHEN** 授权状态为 `denied` 或 `restricted`
- **THEN** 展示说明文案与「打开系统设置」按钮，不展示空白网格

#### Scenario: 从系统设置改完权限返回
- **WHEN** 应用从后台回到前台
- **THEN** 重新读取授权状态，若已变为可用则自动加载图片

