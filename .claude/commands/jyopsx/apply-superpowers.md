---
name: "JYOPSX: Apply Superpowers"
description: Superpowers 高质量实施工作流（Writing Plans → Worktree → SDD/Executing Plans → 分支收尾）
allowed-tools: Bash(openspec:*)
category: Workflow
tags: [workflow, experimental]
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


将已就绪的 OpenSpec 变更接入 Superpowers 高质量实施流程。相较 /jyopsx-apply，本命令强制生成文件级 Implementation Plan、隔离工作区、逐任务实施与 Review、双层任务对账。

**输入**: 可选变更名称与偏好参数（--workspace worktree|current，--executor sdd|executing-plans）。

**阶段切换协议（最高优先级）**
每进入需要子 skill 的阶段前，**必须使用 Skill 工具**实际加载对应 Superpowers skill（superpowers:writing-plans、superpowers:using-git-worktrees、superpowers:subagent-driven-development 或 superpowers:executing-plans、superpowers:finishing-a-development-branch），严禁凭记忆复述；缺失即停并提示安装，不降级、不回退其他 Apply。

**阶段流水线**（必须按序）
0. 偏好解析：参数 → 自然语言 → 会话要求 → `jy-openspec config get implementation.workspace|executor`（返回码非 0 即未配置）→ 询问；本次覆盖不写回配置；矛盾即问。
1. Action 消费：`status --json`（planningHome/changeRoot/artifactPaths/actionContext）与 `instructions apply --json`（changeDir/contextFiles/tasks/state）各执行一次；blocked/all_done 即停；固化绝对路径。
2. 能力预检：副作用前确认所需 skill 可发现。
3. Writing Plans：复用判定（`<changeDir>/implement-plan.md` + 来源基线哈希，tasks 勾选归一化，禁 mtime）→ 生成 Plan 落盘 `<changeDir>/implement-plan.md`，头部含 Change 名称、来源基线、OpenSpec Task 映射、工作区登记；只读映射校验，漂移引导 /jyopsx-update；Executor 已解析时 Execution Handoff 不再询问。
4. Workspace：current 报告分支即可；worktree 先按工作区登记重入，否则加载 using-git-worktrees；就绪后回写登记。路径纪律：OpenSpec 工件与 Plan 只走固化绝对路径、严禁碰 Worktree 内 openspec/ 副本；子代理 dispatch 带 Worktree 绝对路径并首步 `git rev-parse --show-toplevel` 校验落点。
5. 实施：sdd → subagent-driven-development（宿主不兼容即停不降级）；executing-plans → executing-plans（不擅自切换）。
6. 对账收尾：OpenSpec Task 的全部 Plan Task 过 Review 后才勾选 tasks.md（写入固化的绝对路径（主仓库/Store），不写 Worktree 内副本）；最终整分支 Review → finishing-a-development-branch 用户决定分支去向。

**红线**
- 完成后汇总并停止；严禁自动运行 jyopsx-verify / jyopsx-retro / jyopsx-archive。
- 任一阶段失败或阻塞时停下请示。
