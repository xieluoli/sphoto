---
name: jyopsx-apply-superpowers
description: 【编排型】Superpowers 高质量实施工作流（Writing Plans → Worktree → SDD/Executing Plans → 分支收尾）。将已就绪的 OpenSpec 变更接入 Superpowers 实施流程：生成文件级 Implementation Plan、隔离工作区、逐任务子代理实施与 Review、双层任务对账。适用于：需要高质量护栏的 OpenSpec 变更实施。不适用于：简单改动（用 jyopsx-apply-change）、非 OpenSpec 场景、未安装 Superpowers 的环境。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires jy-openspec CLI and superpowers skills (writing-plans, using-git-worktrees, subagent-driven-development or executing-plans, finishing-a-development-branch).
metadata:
  author: jy-openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


# OpenSpec 变更实施 — Superpowers 工作流

将已完成 Propose 的 OpenSpec Change 接入 Superpowers 高质量实施流程。OpenSpec 负责事实源（Change、Schema、上下文、高层进度），Superpowers 负责实施方法（Plan、Worktree、实施、Review、分支收尾），本 skill 只做适配与对账。

## 输入与变更名称

**输入**: 可选变更名称与偏好参数（如 `/jyopsx-apply-superpowers add-auth --workspace worktree --executor sdd`）。

**变更名称确定规则**:
1. 用户提供了名称，直接使用。
2. 对话上下文可推断，自动识别。
3. 只有一个活动变更，自动选择。
4. 否则运行 `jy-openspec list --json` 请用户选择。

确定后声明："当前变更：`<name>`"。

## 阶段切换协议（最高优先级）

每次进入需要子 skill 的阶段前，**必须使用 Skill 工具**实际加载并调用对应的 Superpowers skill，严禁凭对话记忆直接复述该 skill 的步骤。违反此协议会使本 workflow 退化为"只加了个壳的 apply"。

若环境中对应 skill 未安装、不可发现，或加载后内容明显不具备该阶段所需能力，**停下请示用户**（提示安装或升级 Superpowers），严禁以"模拟"或"记忆复述"方式跳过，严禁回退到其他 Apply 工作流。不读取 Superpowers 版本号，不做版本分支。

必需 skill：`superpowers:writing-plans`、`superpowers:using-git-worktrees`、`superpowers:finishing-a-development-branch`，以及按 Executor 二选一：`superpowers:subagent-driven-development` 或 `superpowers:executing-plans`。

## 工作流总览

```
阶段 0: 偏好解析（Workspace / Executor）
阶段 1: OpenSpec Action 消费（status + instructions apply，各执行一次）
阶段 2: 能力预检（Superpowers skills 可发现性）
阶段 3: Writing Plans（生成或复用 implement-plan.md + 只读映射校验）
阶段 4: Workspace（using-git-worktrees / 当前目录）
阶段 5: 实施（SDD 或 Executing Plans）
阶段 6: 对账与收尾（tasks.md 勾选 → 最终 Review → finishing-a-development-branch → 汇总停止）
```

## 阶段 0: 偏好解析

Workspace 与 Executor 两项偏好**独立解析**，优先级：

```
本次命令结构化参数 → 本次调用中的明确自然语言 → 当前会话中最新且仍适用于本次变更的明确要求 → 全局用户偏好 → 询问用户
```

全局偏好读取（返回码非 0 即未配置，进入下一优先级，不当作隐式默认）：

```bash
jy-openspec config get implementation.workspace   # worktree | current
jy-openspec config get implementation.executor    # sdd | executing-plans
```

自然语言映射（至少覆盖）：

| 表达 | 解析 |
|---|---|
| 不用 Worktree / 当前目录 / 当前分支实施 | workspace=current |
| 创建隔离区 / 使用 Worktree | workspace=worktree |
| 不派子代理 / 顺序直接执行 | executor=executing-plans |
| 使用 SDD / 子代理逐任务实施 | executor=sdd |

规则：
- 本次参数与自然语言覆盖只影响当前运行，**不写回**配置；仅用户明确说"以后默认如此/更新我的偏好"时才执行 `jy-openspec config set`。
- 同次输入自相矛盾时不猜测，指出冲突并询问。
- 两项均缺失时可在同一次交互中一起询问（Executor 推荐 SDD）。
- 已解析的偏好在后续阶段以"已声明偏好"传入各 skill：`writing-plans` 结尾的 Execution Handoff 询问视为已回答，`using-git-worktrees` 的 consent 询问不再出现。偏好只消除选择性询问，不跳过真正的阻塞（Baseline 失败、Plan 冲突、宿主不兼容等）。

## 阶段 1: OpenSpec Action 消费（各执行一次）

分别运行 `status --json` 与 `instructions apply --json`：

```bash
jy-openspec status --change "<name>" --json
jy-openspec instructions apply --change "<name>" --json
```

字段来源（不要在错误的命令输出里找字段）：
- `status`：`planningHome`、`changeRoot`、`artifactPaths`、`actionContext`。
- `instructions apply`：`changeDir`、`contextFiles`、`tasks`、`progress`、`state`、`root`。

变更可能位于 Store（仓库外集中规划库），**固化此处解析出的绝对路径**，后续所有 OpenSpec 工件与 Plan 的读写只用这些绝对路径。

按 `state` 分支：
- `blocked`：停止，引导用户运行 `/jyopsx-continue` 补齐缺失工件，不进入后续阶段。
- `all_done`：停止，提示后续显式动作（verify / retro / archive）。
- `ready`：渐进读取 `contextFiles` 列出的每个文件（proposal、specs、design、tasks 等，以返回为准），然后继续。

整个运行中 `status` 与 `instructions apply` **各执行一次**；Workspace 切换后严禁重复执行或重新解析 openspec 根。

## 阶段 2: 能力预检

在产生任何副作用（建 Worktree、写 Plan）之前：
- 宿主能列出 skill 时，确认公共必需 skill 可发现；Executor 已解析时同时确认所选执行 skill。
- 宿主不能预列时，在真实加载时处理"未找到"。
- 缺失 → 停止并提示安装 Superpowers，不降级、不模拟。

## 阶段 3: Writing Plans

**Plan 复用判定**（先于生成）：检查 `<changeDir>/implement-plan.md` 是否存在。存在时核对其"OpenSpec Source Baseline"（各工件内容哈希；tasks 先把 `[x]`/`[X]` 归一为 `[ ]` 再取哈希）：
- 全部一致 → 复用该 Plan，跳到阶段 4（按其"工作区登记"优先重入）。
- 任一变化 → Plan 过期，重新生成。
- 严禁用 mtime 判断。

**生成**：使用 Skill 工具加载 `superpowers:writing-plans`，输入为 contextFiles 全部内容 + 当前代码库 + actionContext + 项目约束。落盘位置以"已声明偏好"传入：**`<changeDir>/implement-plan.md`**（用户显式声明其他位置时尊重用户）。生成日期写入 Plan 头部。

JY 在 Plan 头部补充（缺一不可）：
1. **OpenSpec Change** 名称；
2. **来源基线**：上述各工件内容哈希表；
3. **OpenSpec Task 映射**：每个 Plan Task 标注 `**OpenSpec Tasks:** <编号>`，允许多对多；
4. **工作区登记**：Branch 与 Worktree 路径占位，阶段 4 就绪后回写。

**只读映射校验**（只产出发现，不回改任何工件）：每个未完成的 OpenSpec Task 至少被一个 Plan Task 覆盖。发现以下情况必须停止，引导用户走 `/jyopsx-update` 更新 OpenSpec 工件，不自造回改：Specs 与 Design 冲突；Tasks 无法覆盖 Specs；代码事实使设计不可实施；必须新增超出 Proposal 范围的行为；映射校验发现不可自行裁决的矛盾。

Executor 已解析时，`writing-plans` 结尾的 Execution Handoff 询问视为已回答，直接进入阶段 4。

## 阶段 4: Workspace

- `workspace=current`：不创建 Worktree，报告当前分支后进入实施（用户级 current 配置视为长期明确授权，包含允许在当前默认分支继续）。
- `workspace=worktree`：**恢复场景先重入**——若 Plan 工作区登记有 Worktree 路径，用 `git worktree list` 匹配；存在则进入该 Worktree 继续（不新建，不因分支已存在而失败）。否则使用 Skill 工具加载 `superpowers:using-git-worktrees`，以"已声明偏好"传入，由其负责检测、原生工具选择、目录与 ignore 校验、依赖安装与 Baseline Tests。Baseline 失败即停。

Workspace 就绪后，把 Branch 与 Worktree 绝对路径**回写**到 Plan 的工作区登记（Plan 在 change 目录，任何工作区内都可经绝对路径写入）。

**路径纪律（实施全程强制）**：
1. OpenSpec 工件与 Plan 的读写一律使用阶段 1 固化的 `changeDir` 绝对路径；`openspec/` 在 Worktree 内的副本严禁读写。
2. 派发子代理时 dispatch 必须携带 Worktree 绝对路径，并要求子代理首步执行 `git rev-parse --show-toplevel` 校验自己位于 Worktree 内；每个任务完成后在 Worktree 内核对 `git status` 与 `git log` 确认提交落点。
3. 关键产物不留未提交中间态跨越 Workspace 切换或会话边界；实施代码按 Plan 步骤高频提交。

## 阶段 5: 实施

按 Executor 使用 Skill 工具加载对应 skill 并遵循其完整流程：
- `sdd` → `superpowers:subagent-driven-development`（宿主无子代理能力时报告不兼容并**停止，不静默降级**）。
- `executing-plans` → `superpowers:executing-plans`（宿主支持子代理也尊重用户选择，不擅自切换）。

实施输入是 `<changeDir>/implement-plan.md`（绝对路径）。SDD 的 Ledger 位于 Worktree 根下 `.superpowers/sdd/progress.md`，属 Worktree 内临时文件。

**中断恢复顺序**：重入登记 Worktree 后从 Ledger 继续 → Worktree 已不存在时按 git log → Plan 复选框 → tasks.md 恢复进度，再重走阶段 4。

## 阶段 6: 对账与收尾

- 进度对账：某 OpenSpec Task 对应的**全部** Plan Task 达到完成判据（SDD 下 = Implementer 完成 + 测试通过 + Task Review 无未解决重要问题）后，才把 `tasks.md` 该项勾选为 `[x]`；勾选写入阶段 1 固化的绝对路径（主仓库或 Store），严禁写 Worktree 内副本。
- 实施中发现需求或设计漂移：停止，引导 `/jyopsx-update`。
- 全部任务完成：按 Executor skill 完成最终整分支 Review，然后使用 Skill 工具加载 `superpowers:finishing-a-development-branch`，按其原生菜单由用户决定分支去向（合并/PR/保留/丢弃；本地合并成功后才清理 Worktree）。

## 终止守则（红线）

- 汇总本次完成的 Plan Tasks、对账后的 OpenSpec Tasks、测试与 Review 证据、剩余阻塞项，然后**停止**。
- **严禁自动激活** `jyopsx-verify`、`jyopsx-retro`、`jyopsx-archive`；必须提示用户手动运行：
  > "实施完成。请确认后按需手动运行：/jyopsx-verify <变更名> · /jyopsx-retro <变更名> · /jyopsx-archive <变更名>"
- 任一阶段失败或阻塞时停下请示，不得跳过。
- 严禁凭记忆复述任何子 skill 的步骤，必须通过 Skill 工具实际加载。
