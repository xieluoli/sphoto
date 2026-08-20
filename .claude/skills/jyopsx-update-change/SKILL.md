---
name: jyopsx-update-change
description: 更新 OpenSpec 变更：修订已有的规划工件并保持彼此一致。当用户想修订变更计划、把新决策合入计划、或在手工编辑后调和工件时使用。绝不修改代码。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文与用户交流，并输出中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


修订变更中已有的规划工件（Planning Artifacts），并保持它们彼此一致。绝不修改代码。

**输入**: 可选指定变更名称。如果省略，检查是否可以从对话上下文中推断。如果模糊不清，**必须**提示用户从可用变更中选择。

**执行步骤**

1. **如果未提供变更名称，提示用户选择**

   运行 `jy-openspec list --json` 获取按最近修改时间排序的可用变更。使用 **AskUserQuestion tool** 让用户选择要更新的变更。

   展示最近修改的 3-4 个变更作为选项，包含：
   - 变更名称
   - Schema（取 `schema` 字段，缺省显示 "spec-driven"）
   - 状态（如 "0/5 tasks"、"complete"、"no tasks"）
   - 最近修改时间（取 `lastModified` 字段）

   将最近修改的变更标记为 "(Recommended)"，它通常就是用户想更新的那个。

   **重要提示**: 不要猜测或自动选择变更。始终让用户手动选择。

2. **获取变更的工件状态**
   ```bash
   jy-openspec status --change "<name>" --json
   ```
   解析 JSON 以了解当前状态，响应包含：
   - `schemaName`: 当前使用的工作流 Schema（如 "spec-driven"）
   - `artifacts`: 工件数组及其状态（"done"、"ready"、"blocked"）
   - `isComplete`: 所有工件是否已完成
   - `planningHome`、`changeRoot`、`artifactPaths`、`actionContext`: 路径与作用域上下文。使用这些字段，不要假设仓库内的相对路径。

   工件的 id 和路径来自当前激活的 Schema —— **不要**假设它们，也**不要**针对硬编码的工件名称写分支逻辑。自定义 Schema 必须无需修改即可工作。

   要编辑的文件是 `artifactPaths.<id>.existingOutputPaths` —— 磁盘上真实存在的具体文件，glob 类工件（如 `specs/**/*.md`）已展开。**不要**写入 `resolvedOutputPath`：对 glob 工件而言它仍是 glob 模式，不是真实文件。

3. **理解用户诉求**
   - 如果用户要求特定修订（如"设计里改用 X"），以此作为起始编辑。
   - 如果只说了"更新"/"保持一致"，则视为一致性审查：通读现有工件，互相比对矛盾、缺漏和重复。

4. **通读并调和**
   - 阅读本次诉求涉及的工件及该变更的其他现有工件。
   - 应用请求的编辑，然后**双向**检查其余工件与它的一致性：对靠后工件的修改也可能要求回头修订靠前的工件。构建顺序只是阅读顺序，不限制可以修订哪个工件。
   - 记录所有因此不一致、缺失或矛盾的内容。
   - 只修订已存在的文件（`existingOutputPaths`）。**不要**创建尚不存在的工件，也**不要**在 glob 工件下新造文件 —— 记录下来并引导用户使用 `/jyopsx-continue-change` 创建。
   - 如果变更本就一致，直接说明，不做任何编辑。

5. **逐个工件确认后再写入**
   - 展示每处拟修订的内容及原因，用户确认后才写入。
   - 用户拒绝某处修订时不要写入，保持该工件不变。
   - 需要大幅重写时，先获取该工件的规则与模板：
     ```bash
     jy-openspec instructions <artifact-id> --change "<name>" --json
     ```

6. **指引下一步（仅指引 —— 绝不代为执行）**
   - 仍有工件缺失 -> 建议 `/jyopsx-continue-change` 创建。
   - 变更已实施（任务已勾选/已 apply）-> 代码可能与修订后的计划不一致，建议 `/jyopsx-apply-change` 把差异落到代码。
   - 全部完成且已实施 -> 建议 `/jyopsx-archive-change`。

**输出要求**

每次执行后展示：
- 修订了哪些工件（以及哪些拟修订被拒绝）
- 移交给 `/jyopsx-continue-change` 的内容（尚未创建的工件或文件）
- 变更当前所处状态与推荐的下一个命令

**硬性约束**
- 只动规划工件 —— **绝不**修改实现代码。如果修订后的计划意味着代码改动，停下并指向 `/jyopsx-apply-change`。
- 使用 `jy-openspec status` 报告的工件 id 和路径；绝不针对硬编码工件名写分支。
- 只编辑 `existingOutputPaths` 中的具体文件；绝不写入 glob 的 `resolvedOutputPath`。
- 不推进构建边界：不新建工件、不在 glob 工件下新建文件 —— 那是 `/jyopsx-continue-change` 的职责。
- 每处编辑写入前必须经用户确认。
- 如果诉求改变的是变更的*意图*而非细化它，建议用 `/jyopsx-new-change` 重新开始（"更新 vs 重开"启发式）。
