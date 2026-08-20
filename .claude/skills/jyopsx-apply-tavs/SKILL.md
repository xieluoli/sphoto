---
name: jyopsx-apply-tavs
description: 【编排型】TAVS 质量流水线（T=TDD → A=Apply → V=Verify → S=Simplify）。将 OpenSpec 变更实施包装为四阶段质量工作流，通过 Skill 工具逐阶段调用子 skill，强制加装质量护栏。适用于：复杂功能实施 / 需要质量保障的 OpenSpec 变更。不适用于：简单改动（请用 jyopsx-apply-change）、纯调试、探索性编码、非 OpenSpec 场景。
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires jy-openspec CLI, superpowers skills (test-driven-development, verification-before-completion), and simplify skill.
metadata:
  author: jy-openspec
  version: "1.0"
  generatedBy: "1.6.1-alpha.0"
---

【强制使用中文】作为资深研发助手，你需要全程使用简体中文。

**Store 选择:** 如果用户点名了某个 store（store 是本机注册的独立 OpenSpec 规划仓库），或工作内容位于某个 store 中，先运行 `jy-openspec store list --json` 查看已注册的 store id，然后在读写 specs 和 changes 的命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`）上传入 `--store <id>`。其他命令不接受该参数。命令输出的提示信息已带上该参数；后续操作请保留它。未指定 store 时，命令作用于最近的本地 `openspec/` 根目录。


# OpenSpec 变更实施 — TAVS 质量流水线

TAVS = TDD → Apply → Verify → Simplify。本 skill 将 OpenSpec 的 apply 实施流程与质量保障手段编排为一个完整工作流。每个阶段各自解决不同的质量风险：TDD 确保意图被测试覆盖，Apply 执行实际编码，Verify 确认产出符合预期，Simplify 消除实施中引入的冗余。

## 输入与变更名称

**输入**: 可选指定变更名称（如 `/jyopsx-apply-tavs login-refactor`）。

**变更名称确定规则**（一旦确定，贯穿所有 4 个阶段）:
1. 如果用户提供了名称，直接使用。
2. 如果对话上下文中可推断，自动识别。
3. 如果只有一个活动变更，自动选择。
4. 否则运行 `jy-openspec list --json` 请用户选择。

确定后声明："当前变更：`<name>`"，后续所有 `jy-openspec` 命令均使用 `--change "<name>"` 参数。

## 阶段切换协议（最高优先级）

每次从一个阶段进入下一个阶段前，**必须使用 Skill 工具**实际加载并调用对应的子 skill，严禁凭对话记忆直接复述该 skill 的步骤。违反此协议会导致所有守则失效，使本 workflow 退化为"只加了个壳的 apply"。

每阶段开始时声明："进入阶段 N/4：<名称>"，然后**立刻**通过 Skill 工具调用对应 skill，等待其内容加载完成后再按其指引执行。

若环境中对应 skill 未安装或不可用，**停下请示用户**，严禁以"模拟"或"记忆复述"方式跳过。

## 工作流总览

```
阶段 1: TDD（测试驱动开发）
    ↓
阶段 2: Apply（实施变更）
    ↓
阶段 3: Verification（验证完成）
    ↓
阶段 4: Simplify（简化代码）
```

---

## 阶段 1: 测试驱动开发 (TDD)

**目的**: 在写实现代码之前，先为即将实施的任务编写测试，确保实施目标清晰且可验证。

**调用方式**: 必须使用 Skill 工具调用 `superpowers:test-driven-development`。

**具体步骤**:
1. 先通过 `jy-openspec status` 和 `jy-openspec instructions apply` 获取当前变更的任务列表和上下文。
2. 阅读 contextFiles（proposal, design, tasks 等），理解实施目标。
3. 基于待办任务，使用 TDD skill 的流程：先写失败的测试，明确每个任务的验收标准。
4. 确认测试就绪后，进入下一阶段。

**阶段完成标志**: 针对待实施任务的测试已编写且当前为失败状态（红灯）。

---

## 阶段 2: 实施变更 (Apply)

**目的**: 按照 OpenSpec 的任务清单逐项编码实现。

**调用方式**: 必须使用 Skill 工具调用 `jyopsx-apply-change`。

**具体步骤**:
1. 按照 jyopsx-apply-change 的完整流程执行（选择变更 → 获取指令 → 读取上下文 → 循环实施任务）。
2. 每完成一个任务，确保之前写的测试从红变绿。
3. 所有任务完成后，运行完整测试套件确认无回归。

**阶段完成标志**: tasks.md 中的待办项全部勾选，测试全部通过。

---

## 阶段 3: 验证完成 (Verification)

**目的**: 在声称工作完成之前，用客观证据确认产出符合预期，避免遗漏。

**调用方式**: 必须使用 Skill 工具调用 `superpowers:verification-before-completion`。

**具体步骤**:
1. 运行所有相关测试命令，确认通过。
2. 检查构建是否成功。
3. 回顾 design.md 和 proposal.md，确认实施与设计一致。
4. 确认没有遗漏的任务或边界情况。

**阶段完成标志**: 所有验证命令的输出已确认为通过，证据已记录。

---

## 阶段 4: 简化代码 (Simplify)

**目的**: 审查本次变更引入的代码，消除重复、提升可读性、优化效率。

**调用方式**: 必须使用 Skill 工具调用 `simplify`。

**具体步骤**:
1. 审查本次变更涉及的所有文件。
2. 检查是否有可复用的现有代码、不必要的抽象、或可简化的逻辑。
3. 应用改进，再次运行测试确认无回归。

**阶段完成标志**: 代码已优化，测试仍然全部通过。

---

## 终止守则（红线）

- 阶段 4 结束后，**严禁自动激活 `jyopsx-archive-change` 或 `jyopsx-retro`**。
- 必须停下，汇报四阶段总产出，提示用户：
  > "工作流已完成四阶段。请确认无误后手动运行：
  >   - `/jyopsx-retro <变更名>`  进行复盘
  >   - `/jyopsx-archive <变更名>` 进行归档"

## 守则 (Guardrails)

- 每阶段开始前声明："进入阶段 N/4：<名称>"。
- 每阶段结束时汇报本阶段产出 + 下一阶段预告。
- 任一阶段失败或阻塞时停下请示，不得自动跳至下一阶段。
- 严禁凭记忆复述任何子 skill 的步骤，必须通过 Skill 工具实际加载。
