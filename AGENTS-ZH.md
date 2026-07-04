# Agent 贡献规范

Language: [English](AGENTS.md) | 简体中文

本文档定义了 AI agent（及操作它们的人）在本仓库工作时须遵守的规则——无论您是提交拉取请求，还是在本地协助维护者开发。本文档是对 [贡献指南](CONTRIBUTING-ZH.md) 和 [兼容性政策](COMPATIBILITY_POLICY.md) 的补充，且绝不凌驾于它们之上。

dio 是 Dart/Flutter 生态中被依赖最多的包之一。一次草率的改动就可能破坏数以万计的下游项目。在这里贡献不是儿戏：每一个改动都必须有动机、有测试、保持兼容。

## 1. 动机优先——禁止臆想式改动

**不要凭空制造工作。** 只有解决真实存在的问题的改动才会被接受。

- 每个非琐碎的改动都必须能追溯到具体动机：一个可复现的 bug、一个被接受的 issue/discussion、一份 RFC 式的提案、或维护者的明确要求。「这看起来有用」不是动机。
- 落地一个 feature 之前，必须在 issue 或 PR 描述中回答以下问题——答不上来就不要开 PR：
  1. 当前的 dio 有什么做不到（或做得不好）的？
  2. 谁需要它？在什么真实场景中需要？
  3. 为什么它必须进入 dio 本体，而不是通过 interceptor、adapter、transformer 或独立的包来实现？dio 被有意设计为可扩展的，大多数需求靠扩展点即可满足，无需改动核心。
  4. 代价是什么——API 面、维护负担、兼容性风险？
- 一个 PR 只解决一件事。不要把多个互不相关的功能或修复捆绑进同一个 PR。捆绑式的「改进大礼包」可能不经审阅直接关闭。
- 任何面向用户的 feature，在动手写代码**之前**必须先开 issue 讨论，除非维护者已经明确提出需求。没有事先讨论、缺乏明确动机的 feature PR 既浪费您的 token 也浪费维护者的时间，可能被直接关闭。

## 2. 逻辑改动必须有测试

每个行为上的改动都必须由测试证明。

- 任何逻辑改动都需要新增测试或调整现有测试，且测试必须「没有此改动则失败、有此改动则通过」。Bug 修复必须附带能复现原始报告的回归测试。
- CI 会在每个 PR 上报告覆盖率差异。改动代码的覆盖率不得倒退；新增的代码路径（包括错误路径）必须被覆盖。
- 测试必须**有效且不重复**：
  - 断言可观察的行为，而不是实现细节。
  - 不要为了抬高覆盖率数字而添加只是重复执行已覆盖路径的测试。
  - 先搜索现有测试套件——优先扩展已有的测试分组，而不是创建近乎重复的文件。
- 把测试放在正确的位置：
  - 包内特有的行为 → `<package>/test/`。
  - 必须在所有 adapter/平台上一致的行为 → 共享的 `dio_test` 包。
- 在声称检查通过之前，先在本地实际运行：

  ```bash
  melos run format   # 或 format:fix
  melos run analyze
  melos run test     # 或指定目标：test:vm / test:web / test:flutter
  ```

- 没有运行过测试就绝不声称测试通过。没有实际完成的 PR checklist 条目绝不打勾。谎报验证状态可能导致 PR 被直接关闭。

## 3. 兼容性不容侵犯——避免 breaking change

dio 的公开 API 是与庞大下游生态的契约。除非维护者另有决定，请把每个公开符号都视为冻结的。

- **默认不做破坏性改动。** 优先做加法：带安全默认值的新可选命名参数、新的类、新的扩展点。
- 在非 major 版本中，绝不改变公开方法签名、移除/重命名公开符号、改变默认行为、或改变抛出的异常类型。
- 如果某个 API 确实必须移除，先废弃并保持其可用：

  ```dart
  @Deprecated('Use XXX instead. This will be removed in 7.0.0')
  ```

  废弃标注必须写明替代方案和移除版本，且只在下一个 major 版本中移除，同时在 `dio/doc/migration_guide.md` 中补充对应条目。
- 不得抬高任何包的 Dart/Flutter SDK 最低约束，除非 [兼容性政策](COMPATIBILITY_POLICY.md) 或其列出的例外情况要求如此。CI 会针对最低支持的 SDK 运行测试；不要使用超出包下限的语言/库特性。
- 同样警惕**行为性**的 breaking change：改变默认值、header 规范化、重定向/错误语义、interceptor 的时序或顺序，即使签名未变也可能破坏下游。
- 如果破坏性改动确实不可避免，请停下来开 issue 交由维护者决定。不要单方面提交。

## 4. 先理解，再改动

- 编辑之前先阅读周边代码和既有模式。遵循现有的风格、命名和模块边界。
- 解决根因，而不是症状。收到症状报告时，先定位真正的缺陷再打补丁。
- 绝不臆测 API——无论是 dio 的内部实现还是第三方包。不确定时去读真实源码（依赖位于 `~/.pub-cache/hosted/pub.dev/<包名>-<版本>/`）以及该包自带的测试/示例。如果 `dart analyze` 提示某个成员不存在，回到源码确认，而不是反复尝试各种变体。
- 保持最小 diff。只改本次改动必须涉及的文件。禁止顺手重构、对未涉及代码重新格式化、升级依赖，或夹带与所述目的无关的 `.gitignore`/CI 修改。

## 5. 只接受生产级质量

- 不接受半成品：不留 `TODO`/`FIXME`，不把 mock 或简化实现当成完整功能提交，不写「以后再优化」的代码。
- 显式处理边界条件和错误路径；绝不静默吞掉错误。
- 如果确实无法完整完成某项工作，明确说明并指出边界——不要假装已经完成。

## 6. 仓库结构与工作流

本项目是使用 [Melos](https://melos.invertase.dev) 管理的单体仓库：

| 路径 | 包 |
|---|---|
| `dio/` | 核心包 |
| `plugins/web_adapter/` | `dio_web_adapter` |
| `plugins/cookie_manager/` | `dio_cookie_manager` |
| `plugins/http2_adapter/` | `dio_http2_adapter` |
| `plugins/native_dio_adapter/` | `native_dio_adapter` |
| `plugins/compatibility_layer/` | `dio_compatibility_layer` |
| `dio_test/` | 供所有 adapter 共享的测试套件 |
| `example_dart/`、`example_flutter_app/` | 示例 |

设置：

```bash
dart pub global activate melos
melos bootstrap
```

每个包独立管理版本、独立发布。注意各包的 **SDK 下限不同**（见各自的 `pubspec.yaml`）。

## 7. Changelog、提交与 PR 卫生

- 更新**每个被改动的包**的 `CHANGELOG.md`，写在 `## Unreleased` 小节下（替换掉 `*None.*`）。每项改动一条简明的 bullet，面向下游用户撰写。不要修改版本号——发版由维护者完成。
- 提交信息和 PR 使用英文。PR 标题遵循仓库现有风格（参考 `git log`），并引用相关 issue。
- 如实填写 PR 模板。公开 API 变化时检查文档（`README.md`、`README-ZH.md`、API 文档注释、示例）。
- 欢迎 agent 辅助的 PR，但提交 PR 的人对它负全责：您必须理解每一行代码、能在 review 中为其答辩，并对 review 意见作出实质性回应。「这是 AI 写的」不是对 review 问题的回答。

## 8. 可能被直接关闭的情形

为了把维护者的时间留给用心的贡献，出现以下情形的 PR 可能会不经详细审阅直接关闭：

- 没有说明动机、没有事先讨论的功能堆砌。
- 多个不相关改动捆绑在一起。
- 逻辑改动没有测试，或测试没有任何有效断言。
- 无关的文件搅动（把格式化清扫、`.gitignore`、CI、文档重组夹带进功能性 PR）。
- 虚假勾选 checklist 条目（例如没跑过测试却声称已运行）。
- 未经维护者事先同意的公开 API 破坏性改动。
