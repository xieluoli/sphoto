---
name: "JYOPSX: Sync"
description: 将变更中的增量规格同步到主规格库
allowed-tools: Bash(openspec:*)
category: Workflow
tags: [workflow, specs, experimental]
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文与用户交流，并输出中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


将变更中的增量规格同步到主规格库。

这是一项 **Agent 驱动** 的操作——你将读取增量规格，并直接编辑主规格文件以应用更改。这允许智能合并。

**输入**: 在 `/jyopsx-sync` 之后可选指定变更名称（例如 `/jyopsx-sync add-auth`）。如果省略，则尝试从上下文中推断或提示选择。

**执行步骤**

1. **选择变更**：运行 `jy-openspec list --json` 并让用户选择拥有增量规格的变更。
2. **读取规格**：同时读取变更下的增量规格 (`spec.md`) 和项目的主规格。
3. **智能合并**：根据意图添加、修改、删除或重命名需求，保留未提及的内容。
4. **结果汇总**：列出哪些 Capability 得到了更新以及具体的变更点。
