---
name: "JYOPSX: Retro"
description: AI 辅助的自动复盘工具。
allowed-tools: Bash(openspec:*)
category: Workflow
tags: [workflow, retro, experimental]
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


此技能专门用于在 OpenSpec 工作流的最后阶段（代码实施完成后、归档之前）执行复盘和笔记沉淀。

**输入**: 参数为变更名称 (kebab-case)。

**步骤**

1. **选择变更**
2. **读取工件**
3. **访谈总结**
4. **写入复盘文档** `notes/retrospective.md`
5. **引导归档**：使用 `/jyopsx-archive` 进行最终归档。
