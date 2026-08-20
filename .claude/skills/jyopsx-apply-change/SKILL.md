---
name: jyopsx-apply-change
description: 从 OpenSpec 变更中实施任务。适用于开始编码、继续实施或按步骤完成任务时。不含质量护栏；如需 TDD / Verification / Simplify 全流程，请使用 jyopsx-apply-workflow（编排型，亦可用 jyopsx-apply-tavs）。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires jy-openspec CLI.
metadata:
  author: jy-openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


从 OpenSpec 变更中实施任务。

**输入**: 可选指定变更名称。如果省略，检查是否可以从对话上下文中推断。如果模糊不清，必须提示用户选择。

**执行步骤**

1. **选择变更**
   如果提供了名称，则使用它。否则：
   - 从上下文推断。
   - 如果只有一个活动变更，自动选择。
   - 否则运行 `jy-openspec list --json` 并请用户选择。
   
   始终声明：“当前变更：<name>”，并告知如何切换（如 `/jyopsx-apply <其他>`）。

2. **检查状态以了解 Schema**
   ```bash
   jy-openspec status --change "<name>" --json
   ```
   使用返回的 `planningHome`、`changeRoot`、`artifactPaths`、`actionContext` 作为路径与作用域上下文，**不要**假设仓库内的相对路径（如 `openspec/changes/<name>/`）——变更可能位于 store 中。

3. **获取实施指令**
   ```bash
   jy-openspec instructions apply --change "<name>" --json
   ```
   根据状态处理：
   - 若状态为 `blocked` (缺少工件): 提示使用 `/jyopsx-continue`。
   - 若状态为 `all_done`: 祝贺并建议归档。
   - 否则：继续实施。

4. **读取上下文文件**
   指令输出中的 `contextFiles` 是「工件 ID -> 具体文件路径数组」的映射（因 Schema 而异，可能是 proposal/specs/design/tasks 或 spec/tests/implementation/docs）。逐一读取 `contextFiles` 下列出的**每个**文件路径。

5. **显示当前进度**
   展示已完成任务数和剩余任务概览。

6. **实施任务（循环直至完成或阻塞）**
   针对每个待办任务：
   - 说明正在处理哪个任务。
   - 进行代码更改（保持简洁聚焦）。
   - 完成后立即更新任务文件：`- [ ]` → `- [x]`。
   - 遇到不明确或设计问题时，停下来请示。

7. **结束或暂停时展示状态**
   汇总本次会话完成的任务及总体进度。

**守则 (Guardrails)**
- 实施前必须读取上下文文件。
- 严禁猜测，不明确时必须询问。
- 每完成一个任务，必须立刻更新任务勾选框。
- 保持代码修改的原子性和聚焦性。
- **红线**：严禁在未得到用户明确指示（如输入 `/jyopsx-archive`）的情况下，自动激活 `jyopsx-archive-change` 技能。当状态达到 `all_done` 时，必须强制停止执行，提示用户进行测试与代码审查，并等待用户的下一步指令。
