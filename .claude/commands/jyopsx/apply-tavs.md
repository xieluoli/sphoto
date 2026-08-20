---
name: "JYOPSX: Apply TAVS"
description: TAVS 质量流水线（TDD → Apply → Verify → Simplify）实施变更
allowed-tools: Bash(openspec:*)
category: Workflow
tags: [workflow, experimental]
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


TAVS = TDD → Apply → Verify → Simplify。将 OpenSpec 变更实施包装为四阶段质量流水线。相较裸用 /jyopsx-apply，本命令强制加装 TDD（先红后绿）、验证、简化三道护栏。

**输入**: 可选变更名称。

**阶段切换协议（最高优先级）**
每进入下一个阶段前，**必须使用 Skill 工具**实际加载对应子 skill，严禁凭记忆复述。

**阶段流水线** (必须按序，不可跳过)
1. **阶段 1/4: TDD** — 调用 `superpowers:test-driven-development`，先写失败测试。
2. **阶段 2/4: Apply** — 调用 `jyopsx-apply-change`，按 tasks.md 编码实施。
3. **阶段 3/4: Verification** — 调用 `superpowers:verification-before-completion`，用证据确认通过。
4. **阶段 4/4: Simplify** — 调用 `simplify`，消除冗余、提升可读性。

**红线**
- 每阶段开始前声明"进入阶段 N/4: <名称>"。
- 阶段 4 结束后严禁自动归档或复盘，必须提示用户运行 `/jyopsx-retro` + `/jyopsx-archive`。
- 任一阶段失败或阻塞时停下请示，不得跳至下一阶段。
