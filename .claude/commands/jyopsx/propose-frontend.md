---
name: "JYOPSX: Propose Frontend"
description: 前端团队专属一步生成所有变更工件（含 Figma 还原视觉边界红线）
allowed-tools: Bash(openspec:*)
category: Workflow
tags: [workflow, artifacts, experimental, frontend]
---

【强制使用中文】作为资深架构师，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


一步完成新变更的立项（前端增强版）：创建变更目录并生成所有必要的工件，含 Figma 还原视觉边界红线。

**输入**: 用户的请求应包含变更名称（kebab-case）或对要构建内容的描述。

**执行步骤**

1. **若输入不明确，询问具体需求**
2. **创建变更目录**：`jy-openspec new change "<name>"`
2.5. **Figma 链接被动监听**：在整个流程中持续监听用户消息中出现的 figma.com 域名链接，自动用 Write 工具写入 `<changeRoot>/figma.md`（格式与 explore-frontend Step 1 一致：`# Figma 设计资源` + `## 链接` + `## 关联变更`）；已存在则追加到 `## 链接` 段尾部。**严禁主动询问**用户"是否涉及 Figma 还原 / 请提供 Figma URL"。仅在用户自然提到链接时才落盘。一旦写入即传递性激活下方红线段。
3. **获取工件构建顺序**：`jy-openspec status --change "<name>" --json`
4. **按顺序生成工件**
   - 生成 design.md 时，必须先加载使用 `writing-plans` 技能。
   - 必须使用简体中文。
   - 若本变更涉及 Figma 还原（figma.md 存在或 proposal.md 含 figma.com 链接），严格遵守下方红线。

## ⚠ 涉及 Figma 还原时的提案边界

**精确触发条件**：figma.md 存在 OR proposal.md 含 figma.com 链接（二者语义等价；非 Figma 还原性的前端变更不触发，避免误伤）。

❌ design.md / tasks.md 禁止出现：hex/rgba 色值、px 任意值类、gradient/shadow 数值、cva variants 内容、还原层技术选型。

✅ design.md 必须含「Figma 节点清单」表（node-id ↔ 用途 ↔ 是否实现）。

✅ design.md 必须含「D-VR 实施纪律」段（apply 阶段必读）。

✅ tasks.md 中 Figma 还原任务（调用 /figma-implement-design 的任务）一律写为三行结构：

> [Figma 还原] 还原「<用途名>」 — 对应 design.md Figma 节点清单第 X 行。
>       实施路径：用 Skill 工具加载 /figma-implement-design SKILL，参数 figma-url=<完整 Figma URL，含 fileKey 与 node-id>。
>       执行约束见 design.md D-VR；业务接入参照 design.md D<k>。

⚠ **非还原任务保持普通 OpenSpec 任务格式**：路由/状态/API/测试/重构等不调用 /figma-implement-design 的任务，不带 [Figma 还原] 标签、不带 执行约束，使用普通 `- [ ] N.M 任务描述` 格式即可。

视觉的唯一权威源始终是 Figma 本身。

5. **完成汇总**
   - 引导："运行 `/jyopsx-apply` 或 `/jyopsx-apply-tavs` 开始执行任务。"
