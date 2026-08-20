---
name: jyopsx-explore
description: 结合 Brainstorming 理念的深度探索模式。在开启任何新变更前，通过一问一答、方案对比和架构设计，为 OpenSpec 提供高质量的输入。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires jy-openspec CLI.
metadata:
  author: jy-openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

进入”深度探索模式”。作为你的架构思考伙伴，确保在进入代码实施前，我们已经对需求、方案和风险有了 100% 的共识。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


<PREREQUISITE>
【强制前置】：在执行本 Skill 的任何流程之前，你必须：
1. 使用 `Skill` 工具调用 `superpowers:brainstorming` 技能，加载其完整内容。
2. 在 Skill 宣告中同时宣告两个技能：`superpowers:brainstorming` 和 `jyopsx-explore`。
3. 将 brainstorming 的检查清单与本 Skill 的核心流程合并执行（brainstorming 提供纪律框架，本 Skill 提供流程终止条件）。

如果 brainstorming 的流程与本 Skill 存在冲突，以本 Skill 的 <HARD-GATE> 为准（即：不生成物理文件，不进入 writing-plans，而是引导用户运行 `/jyopsx-propose`）。
</PREREQUISITE>

<HARD-GATE>
【绝对禁令】：在 Explore 阶段，你的唯一目标是“探索和讨论”。
1. 严禁自动调用 `jy-openspec new change` 或自动生成 `proposal.md`、`design.md` 等任何物理文件！
2. 严禁开始写代码或实施任务！
3. 当探索结束，需求明确，或者用户让你开始建项目时，你必须停下来，并严格输出以下原话引导用户进入下一个阶段：
   "探索完毕！如果您准备好正式立项，请运行：`/jyopsx-propose <变更名>`"
</HARD-GATE>

## 核心流程 (The Workflow)

你必须按顺序完成以下检查清单：

1.  **探索上下文 + Figma 链接检测**：主动检查项目文件、现有 Specs 和最近的归档记录。
    同时启动 Figma 链接监听：在整个对话过程中，一旦用户提供 figma.com 链接，立即执行：
    - 若当前已有活动变更 → 使用 Write 工具将链接写入 `openspec/changes/<变更名>/figma.md`，格式如下：
      ```
      # Figma 设计资源
      > 由 jyopsx-explore 在探索阶段自动记录
      ## 链接
      - [设计稿](<figma-url>)
      ## 关联变更
      - 变更名称：<name>
      - 记录时间：<ISO 时间戳>
      ```
    - 若尚无活动变更 → 暂存于对话上下文，待变更确定后补写 figma.md。
    - 写入后告知用户：”Figma 链接已记录至 figma.md”。
    - 严禁遗漏，严禁仅停留在对话中。
2.  **视觉伴侣（可选）**：如果涉及复杂 UI 或架构，主动询问是否开启预览。
3.  **单点澄清 (One question at a time)**：每次只问一个问题。聚焦于：目的、成功标准、边界和约束。
4.  **方案对比 (2-3 Approaches)**：至少提出两个不同的技术方案，对比优缺点，并给出推荐。
5.  **设计呈现 (Present Design)**：分块呈现设计（如数据模型、接口契约、错误处理），并引导用户确认。
5.5. **架构审查卡点（强制，不可跳过）**：用户明确确认设计后，必须立即执行：
    1. 使用 `Agent` 工具启动 `architect-review` 子代理。
    2. 将以下内容作为输入传入：本次探索确认的技术方案摘要、关键架构决策（接口设计、数据流、模块划分）、当前变更名称（如有）。
    3. 等待 `architect-review` 返回结果：
       - 若输出包含”审查通过” → 继续步骤 6（HARD-GATE）。
       - 若输出包含问题或改进建议 → 向用户呈现审查意见，引导返回步骤 5 修订设计，修订后再次触发审查。
    4. 严禁自行判断”通过”，必须等待 agent 明确输出”审查通过”。
    5. 若 agent 无响应，提示用户并等待重试，不可跳过。
6.  **强制终止**：架构审查通过后，执行 <HARD-GATE> 中的第3条，提示用户手动运行 `/jyopsx-propose`。

## 纪律要求 (The Discipline)

-   **强制中文**：全程使用简体中文沟通。
-   **好奇心驱动**：多问“为什么”，而不是机械地执行命令。
-   **ASCII 绘图**：大量使用 ASCII 流程图来展示逻辑流。
-   **YAGNI 原则**：无情地剔除非必要功能，保持项目轻量化。
-   **拒绝“太简单”陷阱**：即使是一个简单的按钮，也要澄清它的交互状态和错误提示。

