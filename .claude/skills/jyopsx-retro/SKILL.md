---
name: jyopsx-retro
description: AI 辅助的自动复盘工具。在应用实施完成后，读取历史记录、设计和任务，自动填充或提示用户完善复盘文档，最后更新 tasks 状态。
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


此技能专门用于在 OpenSpec 工作流的最后阶段（代码实施完成后、归档之前）执行复盘和笔记沉淀。

**输入**: 用户调用 `/jyopsx-retro [变更名]` 或 AI 判断到了复盘时间。

**执行步骤**

1. **选择变更**
   如果未提供名称，运行 `jy-openspec list --json` 并请用户选择一个处于活动状态的变更。

2. **读取背景工件**
   - 读取该变更目录下的 `proposal.md`, `design.md`, `tasks.md`。
   - 验证目标文件：`<changeRoot>/notes/retrospective.md` 的存在性（`changeRoot` 取自 `jy-openspec status --change "<name>" --json`，不要假设仓库内相对路径）。

3. **对话访谈与 Diff 分析**
   - 告诉用户：“我正在为你生成变更 `<name>` 的自动复盘记录。”
   - 提问：
     > "在这个特性开发过程中，我们遇到了哪些在设计时（design.md）没考虑到的坑？请简要描述一下，或者我可以根据刚才的聊天记录自动为你总结？"
   - **自动总结**：审视当前 Session 历史，捕捉异常（例如 404、挂起、测试失败、依赖替换）等情况。

4. **生成并更新 `retrospective.md`**
   - 提取痛点和解决方案。
   - 使用 `write_file` 创建或更新 `<changeRoot>/notes/retrospective.md`，包含：
     - `## 背景与目标`
     - `## 遇到的问题及挑战`
     - `## 架构/设计偏离说明`
     - `## 总结与后续优化点`

5. **总结输出**
   告知用户复盘已沉淀，并引导运行 `/jyopsx-archive` 进行最终归档。

**守则 (Guardrails)**
- 必须确保内容具体翔实，拒绝废话。
- 重点突出“问题”与“解法”。
