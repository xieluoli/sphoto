---
name: jyopsx-propose-frontend
description: 前端团队专属一步生成所有变更工件（Artifacts）。在通用 propose 全部流程基础上，新增涉及 Figma 设计稿还原时的视觉边界红线，保证 design.md / tasks.md 不冻结视觉细节。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires jy-openspec CLI.
metadata:
  author: jy-openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

【强制使用中文】作为资深架构师，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


一步完成新变更的立项：创建变更目录并生成所有必要的工件。

我将为你创建包含以下文件的变更：
- proposal.md (初衷与目标)
- design.md (技术设计)
- tasks.md (实施步骤清单)

当一切准备就绪，运行 `/jyopsx-apply` 或 `/jyopsx-apply-tavs` 开始编码。

---

**输入**: 用户的请求应包含变更名称（kebab-case）或对要构建内容的描述。

**执行步骤**

1. **若输入不明确，询问具体需求**
   使用 **AskUserQuestion tool** 提问：
   > "您想进行什么变更？请描述您要构建或修复的内容。"
   根据描述推导出一个 kebab-case 名称（例如："增加用户认证" → `add-user-auth`）。

2. **创建变更目录**
   ```bash
   jy-openspec new change "<name>"
   ```
   这将在 CLI 解析出的规划目录（planning home）下创建基础结构。

2.5. **Figma 链接被动监听（不主动询问）**

   在整个 propose-frontend 流程中（步骤 3-5），持续监听用户消息。一旦出现 figma.com 域名链接：
   - 立即检查 `<changeRoot>/figma.md` 是否存在（`changeRoot` 取自 `jy-openspec status --change "<name>" --json`；用 Read 工具尝试读取，文件不存在视为"未落盘"）。
   - **不存在** → 用 Write 工具创建该文件，格式与 explore-frontend Step 1 完全一致：
     \`\`\`
     # Figma 设计资源
     > 由 jyopsx-propose-frontend 在提案阶段自动记录
     ## 链接
     - [设计稿](<figma-url>)
     ## 关联变更
     - 变更名称：<name>
     - 记录时间：<ISO 8601 时间戳>
     \`\`\`
   - **已存在** → 用 Read 工具读取，把新链接追加到 `## 链接` 段尾部（不覆盖已有链接）。
   - 写入/追加后告知用户："Figma 链接已记录至 figma.md"。

   ⚠ **严禁主动询问**：propose-frontend 启动时**不得**主动问"本变更是否涉及 Figma 还原 / 请提供 Figma URL"。仅当用户**自然提到** figma.com 域名链接时才落盘。理由：避免对纯逻辑/状态/重构等非 Figma 变更施加无意义的询问负担。

   ⚠ **传递性激活红线段**：一旦 figma.md 因被动监听首次落盘，propose-frontend 现有「精确触发条件」（figma.md 存在 OR proposal.md 含 figma.com）即生效。本步骤之后才生成 design.md / tasks.md 时，必须按红线段约束生成（含 D-VR 段、Figma 节点清单、新句式 Figma 还原任务）。**不得**先生成无红线段的 design.md / tasks.md，再写 figma.md，留下"红线段静默缺失"的不一致状态。

3. **获取工件构建顺序**
   ```bash
   jy-openspec status --change "<name>" --json
   ```
   解析 JSON 获取 `applyRequires` 数组和工件列表。

4. **按顺序生成工件，直到达到可实施状态**
   使用 **TodoWrite tool** 追踪进度。
   循环处理处于 `ready` 状态的工件：

   a. **针对每个就绪的工件**:
      - 获取指令：
        ```bash
        jy-openspec instructions <artifact-id> --change "<name>" --json
        ```
      - 读取依赖文件获取上下文。
      - **核心规则**：
        - 如果正在生成 **design.md**，必须先加载使用 `writing-plans` 技能，并严格遵循其设计心法。
        - 必须使用简体中文。
        - **若本变更涉及 Figma 设计稿还原**（见下方「涉及 Figma 还原时的提案边界」红线段判定），必须严格遵守红线。
      - 创建工件文件。
      - 提示进度："已创建 <artifact-id>"。

   b. **重复直至所有 `applyRequires` 里的工件状态均为 `done`**。

5. **展示最终状态**
   ```bash
   jy-openspec status --change "<name>"
   ```

---

## ⚠ 涉及 Figma 还原时的提案边界（红线，强制）

**精确触发条件（仅以下两条 OR，二者语义等价）**：
- ① `<changeRoot>/figma.md` 存在（由 explore-frontend 阶段自动落盘）
- ② `proposal.md` 内含 `figma.com` 链接

前端 UI 严禁作为宽泛触发条件 —— "涉及 UI" 这种语义模糊，会误伤纯逻辑/状态/数据/重构等正常前端变更。仅当本变更确实涉及 Figma 设计稿还原（含上述两条精确条件之一）时才触发红线。非 Figma 还原性的前端变更（路由配置 / 状态管理 / API 调用 / 测试编写 / 重构等）**不触发**红线。

红线触发后必须遵守：

❌ **design.md / tasks.md 严禁出现**：
- 颜色（hex 如 `#1a2b3c` / rgba / Tailwind 任意值色类如 `bg-[#xxx]`、`text-[rgba(...)]`）
- 像素值（任意值类如 `w-[1120px]` / `h-[688px]` / `rounded-[28px]` / `p-[24px]`）
- gradient / shadow / blur / opacity 的具体数值或类名
- cva variants 的具体 className 内容
- 还原层技术选择预判（"该用 PNG 还是 SVG"、"用 CSS gradient 还是 SVG ellipse"）
- 在任务描述里描述"应该如何还原"（如"装入 5 个 ellipse SVG 作为装饰"）

✅ **design.md 必须含「Figma 节点清单」表**（视图实施唯一权威源）：

```markdown
## Figma 节点清单

> 实施 UI 任何环节必须用 /figma-implement-design 拉取以下节点，按 SKILL 完整工作流执行还原。
> 严禁在本文档内描述"应该是什么颜色 / 多少 px / 怎么布局"。

| Figma node-id | 用途 | 是否前端实现 |
|---|---|---|
| <id-1> | 主页面 / 路由视图 | ✅ |
| <id-2> | 按钮、输入框等组件多状态规格 | ✅ |
| <id-3> | mockup 外壳（仅展示用） | ❌ |
```

✅ **tasks.md 中 Figma 还原任务**（指调用 /figma-implement-design 的任务）**必须用固定句式**：

```markdown
- [ ] N.M [Figma 还原] 还原「<用途名>」 — 对应 design.md Figma 节点清单第 X 行。
      实施路径：用 Skill 工具加载 /figma-implement-design SKILL，参数 figma-url=<完整 Figma URL，含 fileKey 与 node-id，例：https://www.figma.com/design/<fileKey>/<file-name>?node-id=<node-id>>。
      执行约束见 design.md D-VR；业务接入参照 design.md D<k>。
```

其中 `<用途名>` 取自上方「Figma 节点清单」表的「用途」列；`X` 是该用途在节点清单中的行号。

⚠ **非还原任务保持普通 OpenSpec 任务格式**：路由配置、状态管理、API 接入、测试编写、重构等不调用 /figma-implement-design 的任务，**不带** [Figma 还原] 标签、**不带** 执行约束，使用普通的 `- [ ] N.M 任务描述` 格式即可。

✅ **业务决策（D1, D2, ...）只覆盖业务维度**：路由结构、数据流、状态机、API 契约、错误处理、并发控制、persist、事件总线等。视觉相关一律不写。

✅ **design.md 必须含「D-VR 实施纪律」段**（apply 阶段必读，传递视觉还原契约）：

```markdown
## D-VR: 视觉还原（Visual Restoration）实施纪律

> 凡 tasks.md 中 [Figma 还原] 任务行末尾的「执行约束见 design.md D-VR」引用，均须反向锚定到本段。本段是 apply 阶段视觉还原所有约束的唯一权威源，请**完整阅读后**再开始任务。

- **唯一权威源**：Figma 本身（通过 /figma-implement-design SKILL 拉取）。
  不依赖任何"中间快照"——包括本 design.md、对话上下文、已截过的图。

- **必须步骤**：用 Skill 工具实际加载 /figma-implement-design 完整 SKILL.md，严格按其内部工作流执行 ── 不跳步、不脱出 SKILL 自身指引。具体步骤、资产规范、引入约定等由 /figma-implement-design SKILL 自己定义并演进，本 design.md 不复述（避免越界与漂移）。

- **严禁行为**：
  • 直接调用 mcp__figma__* 原生工具绕过 SKILL 工作流
  • 凭探索/提案阶段对话上下文中的视觉印象写代码
  • 手写 inline SVG / 凭设计稿截图猜测装饰
  • 把 mcp__figma__get_design_context 当成"快速验证记忆"用

- **返工触发**：若发现本 design.md / tasks.md 含具体视觉细节描述
  （hex / px / Tailwind 任意值视觉类等），停下要求返工 propose 阶段，
  严禁按这些描述实现 ── 它们违反 propose 红线，本身就是错的。
```

**理由**：视觉细节一旦冻结进 design.md / tasks.md，与 Figma 之间的更新通道就断了；下游 apply 阶段会优先信任已成文文档而非重新拉 Figma，导致最终代码与设计稿千差万别。视觉的唯一权威源始终是 Figma 本身。

---

**输出要求**

完成后汇总：
- 变更名称与路径
- 已创建的工件清单
- 结束语："所有工件已生成！准备好进入实施阶段。"
- 引导："运行 `/jyopsx-apply` 或 `/jyopsx-apply-tavs` 开始执行任务。"

**守则 (Guardrails)**

- **结构性自检**（仅在涉及 Figma 还原时生效；不做枚举式黑名单 grep，避免脆弱误触）：
  ① design.md 必须含字串 `D-VR`（缺失即返工）
  ② tasks.md 中 `执行约束` 出现次数等于 Figma 还原任务数（每条 Figma 还原任务一次；非还原任务不计入此次数）
- 严禁在工件中复制 `<context>` 或 `<rules>` 代码块。
- 必须读取前置工件后再写新工件。
- 验证每个文件是否真实写入磁盘。
