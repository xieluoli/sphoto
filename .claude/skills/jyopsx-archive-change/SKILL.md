---
name: jyopsx-archive-change
description: 归档已完成的变更。这将把临时的工件（Proposal, Specs, Design）合并到项目的主规格库中。
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


归档已完成的变更并更新项目主规格。

**输入**: 可选指定变更名称。

**执行步骤**

1. **选择变更**
   推断或运行 `jy-openspec list --json` 请用户选择。

2. **验证状态**
   运行 `jy-openspec status --change "<name>" --json`。
   如果任务未全部完成，提示用户确认是否强制归档。

3. **执行归档**
   **重要**: 必须使用 `--yes` 参数跳过交互式确认，因为 AI 无法处理终端交互提示。
   ```bash
   jy-openspec archive "<name>" --yes
   ```
   如果遇到验证错误（如中文规格格式问题），可追加 `--no-validate`：
   ```bash
   jy-openspec archive "<name>" --yes --no-validate
   ```
   此操作会：
   - 更新规划目录（planning home）下 `specs/` 中的主规格文件。
   - 将变更目录移至 `<planningHome.changesDir>/archive/`（路径见 `jy-openspec status --change "<name>" --json` 返回的 `planningHome`，变更可能位于 store 中，不要假设仓库内相对路径）。

4. **确认结果**
   确认归档成功并告知用户主规格已更新。

**守则 (Guardrails)**
- 归档前确保用户没有未提交的代码更改（可选建议）。
- 执行归档命令时必须带上 `--yes` 参数，严禁使用不带参数的裸命令。
- 归档后引导用户查看更新后的主规格。
