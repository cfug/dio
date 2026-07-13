# Agent 贡献规范

Language: [English](AGENTS.md) | 简体中文

本文档定义了 AI agent（及操作它们的人）在本仓库工作时须遵守的规则——无论您是提交拉取请求，还是在本地协助维护者开发。本文档是对 [贡献指南](CONTRIBUTING-ZH.md) 和 [兼容性政策](COMPATIBILITY_POLICY.md) 的补充，且绝不凌驾于它们之上。

dio 是 Dart/Flutter 生态中被依赖最多的 package 之一。一次草率的改动就可能破坏数以万计的下游项目。在这里贡献不是儿戏：每一个改动都必须有动机、有测试、保持兼容。

## 1. 动机优先——禁止臆想式改动

**不要凭空制造工作。** 只有解决真实存在的问题的改动才会被接受。

- 每个非琐碎的改动都必须能追溯到具体动机：一个可复现的 bug、一个被接受的 issue/discussion、一份 RFC 式的提案、或维护者的明确要求。「这看起来有用」不是动机。
- 落地一个 feature 之前，必须在 issue 或 PR 描述中回答以下问题——答不上来就不要开 PR：
  1. 当前的 dio 有什么做不到（或做得不好）的？
  2. 谁需要它？在什么真实场景中需要？
  3. 为什么它必须进入 dio 本体，而不是通过 interceptor、adapter、transformer 或独立的 package 来实现？dio 被有意设计为可扩展的，大多数需求靠扩展点即可满足，无需改动核心。
  4. 代价是什么——API 面、维护负担、兼容性风险？
- 一个 PR 只解决一件事。不要把多个互不相关的功能或修复捆绑进同一个 PR。捆绑式的「改进大礼包」可能不经审阅直接关闭。
- 任何面向用户的 feature，在动手写代码**之前**必须先开 issue 讨论，除非维护者已经明确提出需求。仅仅写一句 `Closes #NNNN` 不等于「事先讨论过」——被引用的 issue 必须体现出维护者已经表达兴趣或认可了这个方向。缺乏这一基础的 feature PR 既浪费您的 token 也浪费维护者的时间，可能被直接关闭。

## 2. 逻辑改动必须有测试

每个行为上的改动都必须由测试证明。

- 任何逻辑改动都需要新增测试或调整现有测试，且测试必须「没有此改动则失败、有此改动则通过」。Bug 修复必须附带能复现原始报告的回归测试。
- CI 会在每个 PR 上报告覆盖率差异。仓库配置的最低阈值很低，那是底线，不是目标：您改动的代码覆盖率不得倒退，新增逻辑（包括错误路径）应由真实断言覆盖。
- 测试必须**有效且不重复**：
  - 断言可观察的行为，而不是实现细节。
  - 不要为了抬高覆盖率数字而添加只是重复执行已覆盖路径的测试。
  - 先搜索现有测试套件——优先扩展已有的测试分组，而不是创建近乎重复的文件。
- 把测试放在正确的位置：
  - package 内特有的行为 → `<package>/test/`。
  - 必须在所有 adapter/平台上一致的行为 → 共享的 `dio_test` package。
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
- 未经废弃流程，不得改变公开方法签名、移除/重命名公开符号、改变默认行为、或改变抛出的异常类型。破坏性改动应归入 major 版本。正如 dio 自己的 [CHANGELOG](dio/CHANGELOG.md) 开篇所述，在无法避免时，破坏性改动**偶尔**也会出现在 minor 版本——这类情况仍需**事先**获得维护者的书面确认，并在 [迁移指南](dio/doc/migration_guide.md) 中留下记录。
- 如果某个 API 确实必须移除，先废弃并保持其可用：

  ```dart
  @Deprecated('Use XXX instead. This will be removed in X.0.0')
  ```

  废弃标注必须写明替代方案和移除版本，且只在下一个 major 版本中移除，同时在迁移指南中补充对应条目。目标是**下一个** major，而不是更远的版本。
- 不得抬高任何 package 的 Dart/Flutter SDK 最低约束，除非 [兼容性政策](COMPATIBILITY_POLICY.md) 或其列出的例外情况要求如此。CI 会针对最低支持的 SDK 运行测试；不要使用超出 package 下限的语言/库特性。
- 同样警惕**行为性**的 breaking change：改变默认值、header 规范化、重定向/错误语义、interceptor 的时序或顺序，即使签名未变也可能破坏下游。
- 如果破坏性改动确实不可避免，请停下来开 issue 交由维护者决定。不要单方面提交。

### 安全与网络关键区域——需要额外谨慎

dio 的部分区域一旦出问题波及面极大。这些区域的改动需要额外小心，PR 描述中必须显式说明改动、并 @ 维护者：

- SSL/TLS 处理与证书 pinning（`badCertificateCallback`、`SecurityContext`、各 adapter 的 `HttpClient` 配置）。
- 重定向处理与跨源行为（重定向策略、header 转发、跨重定向的 cookie 泄漏）。
- Cookie 管理（`dio_cookie_manager`、domain/path 匹配）。
- Header 处理（`Authorization`、`Content-Type`、大小写、重复项）。
- 超时、cancellation、连接池。
- Interceptor pipeline（顺序、错误传递、`next` / `resolve` / `reject` 语义）。
- 请求体编码：`FormData`、multipart 流式、编码探测。

判定标准：如果处理不当会泄漏凭证、让请求永远挂起、或改变发到网络上的数据，就属于敏感区域。

### 依赖变更

不要把顺手的依赖升级夹带进 feature/fix PR。当依赖变更本身就是 PR 的目的时：

- 在描述中说明原因（安全修复、新特性所需、上游弃用等等）。「新的比旧的好」不是原因。
- 在受影响的 `pubspec.yaml` 声明的所有支持 SDK 版本下验证改动。除非 [兼容性政策](COMPATIBILITY_POLICY.md) 允许，否则不得为了容纳新依赖而抬高 package 的 SDK 下限。
- 优先选择能解决问题的最窄约束（patch > minor > major）。
- 显式指出新增的传递依赖——下游用户在意他们的 lockfile。
- Commit 使用 `⬆️ chore`（或 `chore(deps)`）类型。

## 4. 先理解，再改动

- 编辑之前先阅读周边代码和既有模式。遵循现有的风格、命名和模块边界。
- 解决根因，而不是症状。收到症状报告时，先定位真正的缺陷再打补丁。
- 绝不臆测 API——无论是 dio 的内部实现还是第三方 package。不确定时去读真实源码以及该 package 自带的测试/示例。如果 `dart analyze` 提示某个成员不存在，回到源码确认，而不是反复尝试各种变体。依赖源码的默认位置：

  | 平台 | 默认位置 |
  |---|---|
  | macOS / Linux | `~/.pub-cache/hosted/pub.dev/<package>-<version>/` |
  | Windows | `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<package>-<version>\` |

  如果设置了 `PUB_CACHE` 环境变量，请以该变量指向的位置为准。
- **引用任何 RFC、规范或标准之前必须先验证。** Agent 经常臆造 RFC 编号，或把错误的标题安到某个编号上。commit message、changelog 或文档注释里出现错误引用，比不引用还糟——它会误导信任该引用的下游读者和 reviewer。在写下「RFC NNNN」或「如 RFC NNNN 所定义」之前：
  1. 到 `https://www.rfc-editor.org/rfc/rfcNNNN`（或 `https://datatracker.ietf.org/doc/rfcNNNN/`）查证该编号对应的标题，确认它确实定义了你所声称的内容。
  2. 确认你引用或转述的章节锚点真实存在。
  3. 如果无法在线验证，就删掉引用，用自己的话描述行为。不要为了显得权威而瞎编编号。
  本规则适用于 commit message、`CHANGELOG.md`、文档注释、README 以及 PR 描述中的任何文字。

## 5. 只接受生产级质量

- 不接受半成品：不留 `TODO`/`FIXME`，不把 mock 或简化实现当成完整功能提交，不写「以后再优化」的代码。
- 显式处理边界条件和错误路径；绝不静默吞掉错误。
- 如果确实无法完整完成某项工作，明确说明并指出边界——不要假装已经完成。

## 6. 何时停下来问人

Agent 的默认行为是「猜了就做」。请不要。遇到以下情形时，暂停并向操作者确认（或开 issue 讨论）：

- 任务描述模糊，多个合理解读会导致差异明显的实现。
- 修复所报告的问题需要超出请求范围的设计变更。
- 正确的修复触及了明显不在预期范围内的区域（例如为了修一个不相关的 bug 而重命名公开 API，或为了实现一个小功能而重构 interceptor pipeline）。
- 在合理尝试后仍无法复现所报告的问题。
- 请求本身看起来就有问题（例如「bug」其实是预期行为，或「feature」违反了本文档的规则）。

以下情况**不要**停下来问：例行的机械步骤（运行测试/format/analyze、暂存文件、开 draft PR），以及本文档已经明确规定的事项（commit 格式、CHANGELOG、AI 归属）。

## 7. 仓库结构

本项目是使用 [Melos](https://github.com/invertase/melos/tree/main/docs) 管理的单体仓库：

| 路径 | package |
|---|---|
| `dio/` | 核心 package |
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

每个 package 独立管理版本、独立发布。注意各 package 的 **SDK 下限不同**（见各自的 `pubspec.yaml`）。

## 8. Commit、changelog 与 PR 卫生

### 8.1 分支命名

在名为 `category/ticket-id-or-short-description` 的功能分支上工作：

- `category` 与 commit 中使用的 Conventional 类型对应：`feat`、`fix`、`perf`、`refactor`、`docs`、`test`、`chore`、`ci`、`style`。
- 有对应的 **ticket id**（issue 或 PR 号）时优先使用：`fix/2201`、`feat/2555`。两者结合以增强可读性也可以：`fix/2201-cookie-domain-match`。
- 否则使用 **short description**——2–5 个 kebab-case 单词描述改动（`docs/agents-guidelines`、`feat/cors-preflight-warning`、`chore/bump-http2-3.0.0`）。

规则：

- 绝不直接在 `main` 上工作。
- 每个 PR 一个分支；不要把已合并的分支重新用于新的改动。
- 分支名保持 ASCII、小写、简短。

### 8.2 Commit message 格式 —— Gitmoji 或 Conventional

每条 commit 使用 **[gitmoji](https://gitmoji.dev)** 打头，或使用 **[Conventional Commits](https://www.conventionalcommits.org)** 类型前缀。emoji 从 gitmoji 规范中选取——不要自己发明。

```
<gitmoji> <简短祈使句主题>
(或者)
<type>[(<scope>)]: <简短祈使句主题>

[可选正文，每行约 72 字符]

[可选 footer，例如 Closes #1234]
```

本仓库常用的 gitmoji（完整列表见 `git log`）：

| Gitmoji | Conventional 类型 | 用途 |
|---|---|---|
| ✨ `:sparkles:` | `feat` | 新的用户可见特性 |
| 🐛 `:bug:` | `fix` | Bug 修复 |
| ⚡️ `:zap:` | `perf` | 性能优化 |
| ♻️ `:recycle:` | `refactor` | 无行为变化的重构 |
| 📝 `:memo:` | `docs` | 文档 |
| ✅ `:white_check_mark:` | `test` | 只涉及测试 |
| 🚨 `:rotating_light:` | `fix` / `style` | 修复 linter 或 analyzer 警告 |
| 🥅 `:goal_net:` | `fix` / `refactor` | 处理错误 / 改进错误处理 |
| 🔧 `:wrench:` | `chore` | 配置 / 工具链 |
| 👷 `:construction_worker:` | `ci` | CI / workflow 变更 |
| 💚 `:green_heart:` | `ci` | 修复失败的 CI |
| ⬆️ `:arrow_up:` | `chore` | 升级依赖 |
| 🔥 `:fire:` | `chore` / `refactor` | 删除代码或文件 |
| 🎨 `:art:` | `style` | 只涉及格式/结构 |
| 🔖 `:bookmark:` | `chore(release)` | 发版（**仅维护者**） |

规则：

- 主题使用英文祈使句。不要手动加 PR 号——GitHub 在 squash-merge 时会自动追加 `(#N)`。
- Scope 用于澄清（`fix(dio_web_adapter): ...`）；如果 scope 只是重复了路径信息，就省略。
- 位置 0 是 emoji 或者 Conventional 前缀加冒号，然后空格，再是主题。

示例（改编自真实仓库历史）：

```
🐛 Allow `callFollowingErrorInterceptor` when rejecting in `ErrorInterceptorHandler`
perf(dio): reduce `FormData.readAsBytes` memory usage for large payloads
docs: add agent contribution guidelines
```

### 8.3 AI 归属——必须声明

对 AI 参与的透明化是**强制要求**。不要隐瞒，也不要为了「保持 commit 干净」而省略。

- 对每一个产出代码、测试或文档的 AI agent，都要加上 `Co-Authored-By:` trailer：

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  Co-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>
  ```

  身份信息以该 agent 自己公开的形式为准（参考其官方文档或该 agent 在 GitHub 上最近的 commit）。多个 agent → 多条 trailer。
- 同时在 PR 描述中说明**用了哪些 agent、分别参与了哪个阶段**——设计、实现、测试或 review。一句话即可，例如：

  > *Implementation and tests by Devin; local review pass by GLM-5.2.*

- AI 归属不会转移责任。提交 PR 的人对每一行代码负全责，必须理解每一行，并对 review 意见作出实质性回应。「这是 AI 写的」不是对 review 问题的回答。

### 8.4 CHANGELOG 与文档

- 更新**每个被改动的 package** 的 `CHANGELOG.md`，写在 `## Unreleased` 小节下（替换掉 `*None.*`）。
- 每项改动一条简明的 bullet，面向下游用户撰写，而不是面向 reviewer。
- 不要修改版本号——发版由维护者完成。
- 公开 API 变化时，同步检查 `README.md`、`README-ZH.md`、API 文档注释、以及所有受影响的示例。

### 8.5 每次 commit 前自审 diff

提交前始终检查即将进入 commit 的内容：

```bash
git diff                            # 未暂存
git diff --staged                   # 已暂存
git diff <base-branch>...HEAD       # 开 PR / 更新 PR 前的完整分支 diff
```

commit 前必须清除：

- 调试输出（`print`、`debugPrint`、`console.log`、临时日志）。
- 前几次尝试遗留的注释掉的代码。
- 不属于本次改动的文件里的格式化/import 排序变化。
- `pubspec.yaml` / `pubspec.lock` 中不相关的依赖升降。
- 无关文件里的纯空白改动。
- 编辑器/系统垃圾（`.DS_Store`、`.idea/`、个人临时文件）。

如果一段 diff 你说不清为什么会在那里，它就不该进这次 commit。绝不使用 `git add .` 或 `git add -A`——按路径精确 stage。

**同时把 commit message 与暂存的 diff 对读一遍。** 上一次尝试遗留下来的、或从无关 commit 自动补全过来的 message 很容易被漏看，一旦 commit 就会以那种形式永久留在历史里。如果 message 描述的工作和 diff 不一致，两者之中至少有一个是错的。

### 8.6 提交 PR

- 当改动较大、处于探索阶段、或希望在打磨前先获得维护者方向性反馈时，**以 draft PR 形式开启**（`Create draft pull request`）。在本地检查通过、描述完整之后再切换为 Ready for Review。
- 在描述中用 `Closes #NNNN` 引用要关闭的 issue。
- 遵循 §8.3 的 AI 归属规则：说明用了哪些 agent、参与了哪个阶段。
- PR 标题和正文使用英文，风格与 §8.2 的 commit 一致。
- 只勾选真正完成的 checklist 条目。对不适用的条目，保持未勾选并在旁边注明「（不适用——原因）」。不要为了「快点通过 checklist」而勾选。
- **诚实描述已完成的验证——不要写套版式 "Test plan" 勾选清单。** 用一两句话散文式说明你实际验证了什么、怎么验证的：

  > *添加了 15 个单元测试覆盖 method / content-type / custom-header 各种组合；`melos run test:vm` 与 `melos run analyze` 均通过。*

  机械性的前置检查（`dart analyze`、`dart format`）已经由 PR 模板顶部的 checklist 覆盖——不要把它们当作「测试」再列一遍。行为验证指的是「本次改动如果回退，这条检查会失败」的那种检查。

  如果确实有该验证但**无法**在本地验证的部分（需要浏览器 CI、真机、生产负载等等），单独用一小段 **Unverified** 段落说明**为什么**没验。未验证区域等于「已知风险」；这个段落应保持罕见，不能变成默认项。

### 8.7 Review 迭代工作流

PR 开出后：

- **用追加 commit 的方式回应 review 反馈**，不要 squash 后 force-push。Reviewer 依赖增量历史；squash 是 merge 时才做的事情。
- **对已经有 review 评论的分支，避免 `git push --force`**——这会让评论从对应代码位置脱钩。如果确实需要 rebase（例如为解决与 `main` 的冲突），先在 PR 里留言告知 reviewer 再推送。
- **不要通过 close 再 reopen PR** 来重置 review 状态、重跑 CI，或绕过一个阻塞的 review。推一个修复即可。
- **设计层面的 review 反馈是对话，不是指令**。如果一条 review 建议改变的是 PR 的意图（而不仅是实现方式），先回复讨论、达成共识后再动代码。机械地照做一个大改动比不改还糟。
- **只有在你已经在代码里回应了这个意见，并留言说明了改动内容后，才把 review thread 标记为 resolved**——或者由 reviewer 明确说 resolve。不要静默 resolve。
- **CI 失败时**：先读失败任务的日志、定位根因，再推修复。绝不通过反复触发 CI 碰运气。如果测试确实 flaky，请在评论里说明——不要通过禁用测试或加重试掩盖。

## 9. 可能被直接关闭的情形

快速对照表——每一项都是对上文规则的违反。出现下列一种或多种情形的 PR，维护者有权不经详细审阅直接关闭。

| 情形 | 参见 |
|---|---|
| 缺乏动机或事先讨论 | §1 |
| 多个不相关改动捆绑在同一个 PR | §1 |
| 逻辑改动缺少有效、非重复的测试 | §2 |
| 未经维护者事先同意的公开 API 破坏性改动 | §3 |
| 敏感区域改动未通知维护者 | §3 |
| 在 feature/fix PR 中夹带顺手的依赖升级 | §3 |
| 臆造 / hallucinate 的 API 用法 | §4 |
| 未经验证或错误的 RFC / 规范引用 | §4 |
| 顺手重构、格式化清扫、无关的 `.gitignore` / CI 改动 | §4、§8.5 |
| 遗留 `TODO`/`FIXME`、mock 或简化实现冒充成品 | §5 |
| 分支命名不符合 `category/ticket-id-or-short-description` | §8.1 |
| 不合规范的 commit message（缺 gitmoji、类型错误、非英文） | §8.2 |
| 缺失或隐瞒 AI 归属 | §8.3 |
| Diff 中残留调试输出或注释掉的代码 | §8.5 |
| 虚假勾选 PR checklist 条目 | §8.6 |
| Force-push 或 close/reopen 用来重置 review 状态 | §8.7 |
