---
name: jyopsx-sync-specs
description: 将变更中的增量规格（Delta Specs）同步到主规格库中。当用户想要更新主规格而暂不归档变更时使用。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: 需要安装 jy-openspec CLI。
metadata:
  author: jy-openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文与用户交流，并输出中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


将变更中的增量规格同步到主规格库。

这是一项 **Agent 驱动** 的操作——你将读取增量规格，并直接编辑主规格文件以应用更改。这允许智能合并（例如：仅添加一个场景，而不是复制整个需求）。

**输入**: 可选指定变更名称。如果省略，检查是否可以从对话上下文中推断。如果模糊不清，**必须**提示用户选择。

**执行步骤**

1. **如果未提供变更名称，提示用户选择**

   运行 `jy-openspec list --json` 获取可用变更。使用 **AskUserQuestion tool** 让用户选择。

   显示拥有增量规格（位于 `specs/` 目录下）的变更。

   **重要提示**: 不要猜测或自动选择变更。始终让用户手动选择。

2. **寻找增量规格**

   运行 `jy-openspec status --change "<name>" --json`，在 `artifactPaths.specs.existingOutputPaths` 中寻找增量规格文件（不要假设 `openspec/changes/` 相对路径，变更可能位于 store 中）。

   每个增量规格文件包含以下部分：
   - `## ADDED Requirements`: 要添加的新需求。
   - `## MODIFIED Requirements`: 对现有需求的修改。
   - `## REMOVED Requirements`: 要删除的需求。
   - `## RENAMED Requirements`: 要重命名的需求（格式为 FROM:/TO:）。

   如果未发现增量规格，告知用户并停止。

3. **针对每个增量规格，将其应用到主规格**

   对于增量规格文件（`<changeRoot>/specs/<capability>/spec.md`）中的每个 Capability：

   a. **读取增量规格**，理解预期的更改。

   b. **读取主规格**，路径为 `<planningHome.specsDir>/<capability>/spec.md`（可能尚不存在）。

   c. **智能应用更改**：

      **ADDED Requirements (新增需求):**
      - 如果主规格中不存在该需求 -> 添加它。
      - 如果需求已存在 -> 更新它以匹配（视为隐式的修改）。

      **MODIFIED Requirements (修改需求):**
      - 在主规格中找到该需求。
      - 应用更改——这可以是：
        - 添加新场景（无需复制现有场景）。
        - 修改现有场景。
        - 更改需求描述。
      - 保留增量规格中未提及的场景或内容。

      **REMOVED Requirements (删除需求):**
      - 从主规格中删除整个需求块。

      **RENAMED Requirements (重命名需求):**
      - 找到 FROM 需求，重命名为 TO。

   d. **如果 Capability 尚不存在，创建新的主规格**：
      - 创建 `<planningHome.specsDir>/<capability>/spec.md`。
      - 添加“目的” (Purpose) 部分（可以很简短，标记为 TBD）。
      - 添加“需求” (Requirements) 部分，包含新增的需求。

4. **显示汇总**

   在应用所有更改后，进行汇总：
   - 哪些 Capability 已更新。
   - 做了哪些更改（新增/修改/删除/重命名了哪些需求）。

**增量规格格式参考**

```markdown
## ADDED Requirements

### Requirement: 新功能
系统应当执行一些新操作。

#### Scenario: 基本情况
- **当** 用户执行 X
- **那么** 系统执行 Y

## MODIFIED Requirements

### Requirement: 现有功能
#### Scenario: 要添加的新场景
- **当** 用户执行 A
- **那么** 系统执行 B

## REMOVED Requirements

### Requirement: 已废弃的功能

## RENAMED Requirements

- FROM: `### Requirement: 旧名称`
- TO: `### Requirement: 新名称`
```

**核心原则：智能合并**

与程序化的合并不同，你可以应用**局部更新**：
- 要添加场景时，只需在 MODIFIED 下包含该场景——不要复制现有场景。
- 增量代表的是*意图*，而不是整体替换。
- 利用你的判断力进行合理的合并。

**成功时的输出**

```
## 规格已同步：<change-name>

已更新主规格：

**<capability-1>**:
- 新增需求：“新功能”
- 修改需求：“现有功能”（新增了 1 个场景）

**<capability-2>**:
- 创建了新的规格文件
- 新增需求：“另一个功能”

主规格现已更新。该变更仍保持活动状态——请在实施完成后进行归档。
```

**守则 (Guardrails)**
- 在做出更改前，务必同时读取增量规格和主规格。
- 保留增量规格中未提及的现有内容。
- 如果有不明确的地方，请请求澄清。
- 在操作过程中显示你正在更改的内容。
- 该操作应当是幂等的——运行两次应得到相同的结果。
