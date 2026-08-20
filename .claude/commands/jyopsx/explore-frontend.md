---
name: "JYOPSX: Explore Frontend"
description: 前端团队专属深度探索模式（含 Figma 落盘 + 架构审查卡点）。
allowed-tools: Bash(openspec:*)
category: Workflow
tags: [workflow, explore, experimental, thinking, frontend]
---

进入"深度探索模式（前端增强版）"。作为你的架构思考伙伴，确保在进入代码实施前，我们已经对需求、方案和风险有了 100% 的共识。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


<PREREQUISITE>
【强制前置】：在执行本 Skill 的任何流程之前，你必须：
1. 使用 `Skill` 工具调用 `superpowers:brainstorming` 技能，加载其完整内容。
2. 在 Skill 宣告中同时宣告两个技能：`superpowers:brainstorming` 和 `jyopsx-explore-frontend`。
3. 将 brainstorming 的检查清单与本 Skill 的核心流程合并执行（brainstorming 提供纪律框架，本 Skill 提供流程终止条件）。

如果 brainstorming 的流程与本 Skill 存在冲突，以本 Skill 的 <HARD-GATE> 为准（即：不生成物理文件，不进入 writing-plans，而是引导用户运行 `/jyopsx-propose-frontend`）。
</PREREQUISITE>

<HARD-GATE>
【绝对禁令】：在 Explore 阶段，你的唯一目标是"探索和讨论"。
1. 严禁自动调用 `jy-openspec new change` 或自动生成 `proposal.md`、`design.md` 等任何物理文件！
2. 严禁开始写代码或实施任务！
3. 当探索结束，需求明确，或者用户让你开始建项目时，你必须停下来，并严格输出以下原话引导用户进入下一个阶段：
   "探索完毕！如果您准备好正式立项，请运行：`/jyopsx-propose-frontend <变更名>`"
</HARD-GATE>

## 核心流程 (The Workflow)

你必须按顺序完成以下检查清单：

1.  **探索上下文 + Figma 链接捕获 + 截图同步**（HARD-GATE 两步原子）：主动检查项目文件、现有 Specs 和最近的归档记录。
    同时启动 Figma 链接监听：一旦用户提供 figma.com 链接，**立即按两步原子执行**（用户一次粘多条 → 逐条迭代，不批量）：
    - ① **写 figma.md**：若已有活动变更 → Write 至 `<changeRoot>/figma.md`；若无 → 暂存对话上下文。
    - ② **拉截图（必须立即调用，截图必须进入对话上下文）**：用 `mcp__figma__get_screenshot` 拉取节点截图，把图嵌入到当前回复消息中。⚠ 裸 URL 无 node-id → 必须主动请用户提供，严禁默默跳过。截图进入上下文后处理下一条链接；无需向用户口头总结画面，也无需等待用户的视觉理解确认。
    - 严禁：链接已写但截图未拉；截图已拉但未进入对话上下文（图躺在工具响应缓冲里）。
    <HARD-GATE>
    在所有已捕获的 figma.com 链接均完成 ①② 两步原子（即截图已进入对话上下文）前，**不得**进入 Step 3（单点澄清）—— 判定条件是技术事实「截图已进入对话上下文」，不是社交事实「用户已口头对齐」。链接已捕获但截图未读 → Step 3 凭文字脑补 → 需求理解偏离设计稿。
    </HARD-GATE>
1.5. **Figma 处理边界（红线，强制遵守）**

    ✅ 允许：
    - 调 `get_screenshot` 拿截图，围绕截图讨论交互流程、状态、边界场景
    - 记录 Figma URL ↔ 功能模块映射（已落盘到 figma.md）
    - 与用户讨论"是否需要某个状态"、"边界是什么"等产品维度决策

    ❌ 严禁：
    - 调 `get_design_context` / `get_metadata` / `get_variable_defs` 等任何拉详细数据的工具
    - 在产出（对话回答 / 项目记忆 / figma.md）出现：
      * 颜色（hex / rgba / Tailwind 任意值色类）
      * 像素值（width / height / padding / margin / radius）
      * 字号 / 字重 / 字距 / 行高
      * gradient / shadow / blur / opacity 数值或类名
      * 装饰元素结构分析（"5 个 ellipse"、"3 层背景叠加"）
      * 还原层技术选型预判（"该用 PNG 还是 SVG 还是 CSS gradient"）
    - 把 Figma 内部结构性元素（多少层、装饰类型、布局结构）当成"已确认设计决策"

    ⚠ 用户主动提供视觉细节时：
    先回应"已记录此为视觉参考。所有视觉细节将在 apply 阶段由
    /figma-implement-design 从 Figma 重新拉取实现，本阶段不固化。"
    不写入 figma.md 或对话记忆。

    **理由**：视觉细节一旦进入早期上下文就回不去，会污染 propose / apply
    全部下游阶段，导致 apply 阶段"凭印象"实现，与设计稿千差万别。

2.  **视觉伴侣（可选）**：如果涉及复杂 UI 或架构，主动询问是否开启预览。
3.  **单点澄清 (One question at a time)**

    ⚠ **前置 HARD-GATE（二次锁）**：进入本步骤前，figma.md 中**每条已捕获链接**必须已经过 Step 1 的 ①② 两步原子，截图已进入对话上下文。**若有任一链接的截图未进入对话上下文，回到 Step 1 补齐**，不得在本步骤聊需求 —— 凭文字脑补设计稿是已证实的需求理解偏离根因。

    每次只问一个问题。聚焦于：目的、成功标准、边界和约束。
4.  **方案对比 (2-3 Approaches)**：至少提出两个不同的技术方案，对比优缺点，并给出推荐。
5.  **设计呈现 (Present Design)**：分块呈现设计（如数据模型、接口契约、错误处理），并引导用户确认。
5.5. **架构审查卡点（强制，不可跳过）**：用户明确确认设计后，必须立即执行：
    1. 使用 `Agent` 工具启动 `architect-review` 子代理。
    2. 将以下内容作为输入传入：本次探索确认的技术方案摘要、关键架构决策（接口设计、数据流、模块划分）、当前变更名称（如有）。
    3. 等待 `architect-review` 返回结果：
       - 若输出包含"审查通过" → 继续步骤 6（HARD-GATE）。
       - 若输出包含问题或改进建议 → 向用户呈现审查意见，引导返回步骤 5 修订设计，修订后再次触发审查。
    4. 严禁自行判断"通过"，必须等待 agent 明确输出"审查通过"。
    5. 若 agent 无响应，提示用户并等待重试，不可跳过。
6.  **强制终止**：架构审查通过后，执行 <HARD-GATE> 中的第3条，提示用户手动运行 `/jyopsx-propose-frontend`。

## 纪律要求 (The Discipline)

-   **强制中文**：全程使用简体中文沟通。
-   **好奇心驱动**：多问"为什么"，而不是机械地执行命令。
-   **ASCII 绘图**：大量使用 ASCII 流程图来展示逻辑流。
-   **YAGNI 原则**：无情地剔除非必要功能，保持项目轻量化。
-   **拒绝"太简单"陷阱**：即使是一个简单的按钮，也要澄清它的交互状态和错误提示。

