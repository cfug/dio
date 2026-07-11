# Agent Contribution Guidelines

Language: English | [简体中文](AGENTS-ZH.md)

This document defines the rules for AI agents (and the humans operating them)
working on this repository — whether you are contributing a pull request or
assisting a maintainer locally. It supplements, and never overrides,
[CONTRIBUTING.md](CONTRIBUTING.md) and the
[Compatibility Policy](COMPATIBILITY_POLICY.md).

dio is one of the most depended-on packages in the Dart/Flutter ecosystem.
A single careless change can break tens of thousands of downstream projects.
Contributions here are not a playground: every change must be motivated,
tested, and compatible.

## 1. Motivation first — no speculative changes

**Do not invent work.** A change is only acceptable when it solves a problem
that actually exists.

- Every non-trivial change must be traceable to a concrete motivation:
  a reproducible bug, an accepted issue/discussion, an RFC-style proposal,
  or an explicit maintainer request. "This seems useful" is not a motivation.
- Before implementing a feature, answer these questions in the issue or the
  PR description — if you cannot, do not open the PR:
  1. What cannot be done (or is done poorly) with the current dio?
  2. Who needs this, and in which real-world scenario?
  3. Why does it belong in dio itself, instead of an interceptor, an adapter,
     a transformer, or a separate package? dio is intentionally extensible;
     most needs are served by its extension points without core changes.
  4. What is the cost — API surface, maintenance burden, compatibility risk?
- One PR, one concern. Do not bundle several unrelated features or fixes
  into a single PR. Bundled "improvement packs" might be closed unreviewed.
- For any user-facing feature, open an issue for discussion **before**
  writing code, unless a maintainer has already asked for it. A bare
  `Closes #NNNN` is not the same as prior discussion: the referenced issue
  must show that maintainers have expressed interest or accepted the
  direction. Feature PRs without that grounding waste both your tokens and
  the maintainers' time, and might be closed.

## 2. Tests are mandatory for logic changes

Every behavioral change must be proven by tests.

- Any change to logic requires new tests or adjustments to existing tests
  that fail without the change and pass with it. Bug fixes must include a
  regression test that reproduces the original report.
- CI reports coverage diffs on every PR. The published minimum threshold is
  low, but that is a floor, not a target: coverage of code you changed
  should not regress, and new logic (including error paths) should be
  covered by real assertions.
- Tests must be **effective and non-duplicated**:
  - Assert observable behavior, not implementation details.
  - Do not add tests that merely re-execute existing covered paths to
    inflate coverage numbers.
  - Search the existing suites first — extend an existing test group
    instead of creating a near-duplicate file.
- Put tests in the right place:
  - Package-specific behavior → `<package>/test/`.
  - Behavior that must hold across all adapters/platforms → the shared
    `dio_test` package.
- Run the checks locally before claiming they pass:

  ```bash
  melos run format   # or format:fix
  melos run analyze
  melos run test     # or targeted: test:vm / test:web / test:flutter
  ```

- Never state that tests pass without having run them. Never check a PR
  checklist item you have not actually done. Misreporting verification
  status may lead to the PR being closed.

## 3. Compatibility is sacred — avoid breaking changes

dio's public API is a contract with an enormous downstream. Treat every
public symbol as frozen unless a maintainer decides otherwise.

- **Default to non-breaking.** Prefer additive changes: new optional named
  parameters with safe defaults, new classes, new extension points.
- Do not change public method signatures, remove/rename public symbols,
  change default behavior, or alter thrown exception types without going
  through a deprecation cycle. Breaking changes belong in major releases.
  As dio's own [CHANGELOG](dio/CHANGELOG.md) preamble states, unavoidable
  breaking changes may occasionally ship in minor releases — those still
  require maintainer sign-off in advance and an entry in the
  [Migration Guide](dio/doc/migration_guide.md).
- If an API must go away, deprecate first and keep it working:

  ```dart
  @Deprecated('Use XXX instead. This will be removed in X.0.0')
  ```

  Deprecations must state their replacement and the removal version, and
  are only removed in the next major release, together with an entry in
  the Migration Guide. Target the *next* major, not a version beyond that.
- Do not raise the minimum Dart/Flutter SDK constraint of any package
  unless required by the [Compatibility Policy](COMPATIBILITY_POLICY.md)
  or its listed exceptions. CI tests against the minimum supported SDK;
  do not use language/library features beyond a package's lower bound.
- Watch for **behavioral** breaking changes too: changing defaults, header
  normalization, redirect/error semantics, or timing/ordering of
  interceptors can break downstream even when signatures are untouched.
- If a breaking change is genuinely unavoidable, stop and raise it in an
  issue for maintainers to decide. Do not merge-request it unilaterally.

### Extra scrutiny in security- and network-critical areas

Some parts of dio have oversized blast radius when broken. Changes here
require extra care, and the PR description should explicitly call the
change out and @-mention a maintainer:

- SSL / TLS handling and certificate pinning (`badCertificateCallback`,
  `SecurityContext`, adapters' `HttpClient` configuration).
- Redirect handling and cross-origin behavior (redirect policy, header
  forwarding, cookie leakage across redirects).
- Cookie management (`dio_cookie_manager`, domain / path matching).
- Header handling (`Authorization`, `Content-Type`, casing, duplicates).
- Timeout, cancellation, and connection pooling.
- The interceptor pipeline (ordering, error propagation, `next` /
  `resolve` / `reject` semantics).
- Request-body encoding: `FormData`, multipart streaming, encoding
  detection.

Rule of thumb: if getting this wrong could leak credentials, hang a
request forever, or change data on the wire, treat it as sensitive.

### Dependency changes

Do not bundle drive-by dependency bumps into a feature/fix PR. When a
dependency change is itself the point of the PR:

- State the reason in the description (security fix, required for a new
  feature, upstream deprecation, etc.). "Latest is greater" is not a
  reason.
- Verify the change under every supported SDK version declared in the
  affected `pubspec.yaml`. Do not raise the package's SDK lower bound
  just to accommodate the new dependency unless the
  [Compatibility Policy](COMPATIBILITY_POLICY.md) allows it.
- Prefer the narrowest constraint that solves the problem (patch >
  minor > major bump).
- Call out any new transitive dependencies — downstream users care about
  their lockfile.
- Use `⬆️ chore` (or `chore(deps)`) as the commit type.

## 4. Understand before you change

- Read the surrounding code and existing patterns before editing. Match
  the existing style, naming, and module boundaries.
- Fix root causes, not symptoms. When a symptom is reported, locate the
  actual defect before patching.
- Never guess an API — neither dio's internals nor third-party packages.
  Read the actual source and the package's own tests/examples when
  unsure. If `dart analyze` says a member does not exist, go back to the
  source instead of retrying variations. Dependency source locations:

  | Platform | Default location |
  |---|---|
  | macOS / Linux | `~/.pub-cache/hosted/pub.dev/<package>-<version>/` |
  | Windows | `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<package>-<version>\` |

  If the `PUB_CACHE` environment variable is set, use that location
  instead of the platform default.

## 5. Production quality only

- No placeholder work: no `TODO`/`FIXME` left behind, no mocked or
  simplified logic presented as complete, no "will optimize later" code.
- Handle edge cases and error paths explicitly; never swallow errors
  silently.
- If you cannot finish something completely, say so explicitly and state
  the boundary — do not pretend it is done.

## 6. When to stop and ask

Agents default to "guess and proceed". Do not. Pause and check with the
operator (or open a discussion issue) when:

- The task description is ambiguous and multiple reasonable interpretations
  would produce materially different implementations.
- Fixing the reported problem would require design changes that go beyond
  what was asked for.
- The right fix touches an area not obviously in scope (e.g., renaming a
  public API to fix an unrelated bug, or restructuring an interceptor
  pipeline to enable a small feature).
- You cannot reproduce the reported issue after a reasonable attempt.
- The request itself seems wrong (e.g., the "bug" is intended behavior, or
  the "feature" would violate a rule in this document).

Do **not** stop to ask permission for routine mechanical steps: running
tests / format / analyze, staging files, opening a draft PR, or choices
that are already decided by this document (commit format, changelog,
attribution).

## 7. Repository layout

This is a [Melos](https://github.com/invertase/melos/tree/main/docs)
mono-repo:

| Path | Package |
|---|---|
| `dio/` | The core package |
| `plugins/web_adapter/` | `dio_web_adapter` |
| `plugins/cookie_manager/` | `dio_cookie_manager` |
| `plugins/http2_adapter/` | `dio_http2_adapter` |
| `plugins/native_dio_adapter/` | `native_dio_adapter` |
| `plugins/compatibility_layer/` | `dio_compatibility_layer` |
| `dio_test/` | Shared test suites for all adapters |
| `example_dart/`, `example_flutter_app/` | Examples |

Setup:

```bash
dart pub global activate melos
melos bootstrap
```

Each package versions and releases independently. Note that packages have
**different SDK lower bounds** (see each `pubspec.yaml`).

## 8. Commits, changelog, and PR hygiene

### 8.1 Branch naming

Work on a feature branch named `category/ticket-id-or-short-description`:

- `category` matches the Conventional type used in the commit:
  `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `chore`, `ci`,
  `style`.
- Use the tracked **ticket id** when one exists — the issue or PR
  number: `fix/2201`, `feat/2555`. Combining both is fine when it aids
  discoverability: `fix/2201-cookie-domain-match`.
- Otherwise use a **short description** — 2–5 kebab-case words that
  describe the change (`docs/agents-guidelines`,
  `feat/cors-preflight-warning`, `chore/bump-http2-3.0.0`).

Rules:

- Never work on `main` directly.
- One branch per PR; do not reuse a merged branch for a new change.
- Keep branch names ASCII, lowercase, and short.

### 8.2 Commit message format — gitmoji + Conventional

Every commit uses **[gitmoji](https://gitmoji.dev)** at the front and a
**[Conventional Commits](https://www.conventionalcommits.org)** type
prefix. Emojis are chosen from the gitmoji specification — do not invent
new ones.

```
<gitmoji> <type>[(<scope>)]: <short imperative subject>

[optional body — wrap at ~72 chars]

[optional footer, e.g. Closes #1234]
```

Gitmoji commonly used in this repository (see `git log` for the full set):

| Gitmoji | Conventional type | Use for |
|---|---|---|
| ✨ `:sparkles:` | `feat` | New user-facing feature |
| 🐛 `:bug:` | `fix` | Bug fix |
| ⚡️ `:zap:` | `perf` | Performance improvement |
| ♻️ `:recycle:` | `refactor` | Refactor with no behavior change |
| 📝 `:memo:` | `docs` | Documentation |
| ✅ `:white_check_mark:` | `test` | Tests only |
| 🚨 `:rotating_light:` | `fix` / `style` | Fix linter or analyzer warnings |
| 🔧 `:wrench:` | `chore` | Config / tooling |
| 👷 `:construction_worker:` | `ci` | CI / workflow changes |
| 💚 `:green_heart:` | `ci` | Fix a failing CI job |
| ⬆️ `:arrow_up:` | `chore` | Bump a dependency |
| 🔥 `:fire:` | `chore` / `refactor` | Remove code or files |
| 🎨 `:art:` | `style` | Formatting / structure only |
| 🔖 `:bookmark:` | `chore(release)` | Release (**maintainers only**) |

Rules:

- Subject is an imperative English sentence. Do not append the PR number —
  GitHub adds `(#N)` automatically on squash-merge.
- Use scope when it clarifies (`fix(dio_web_adapter): ...`); omit when it
  would just repeat the file path.
- Emoji at position 0. Space, then the Conventional prefix, then subject.

Examples (adapted from actual repo history):

```
🐛 fix(dio): allow `callFollowingErrorInterceptor` when rejecting in `ErrorInterceptorHandler`
⚡️ perf(dio): reduce `FormData.readAsBytes` memory usage for large payloads
📝 docs: add agent contribution guidelines
```

### 8.3 AI attribution — mandatory

Transparency about AI involvement is required. Do not hide it, and do not
skip it "to keep the commit clean".

- Add a `Co-Authored-By:` trailer for **every AI agent** that produced
  code, tests, or docs in the commit:

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  Co-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>
  ```

  Use the identity the agent itself publishes (see its own docs / recent
  commits from that agent on GitHub). Multiple agents → multiple trailers.
- Also disclose in the PR description **which agent(s) were used and for
  what stage** — design, implementation, tests, or review. One line is
  enough, e.g.:

  > *Implementation and tests by Devin; local review pass by GLM-5.2.*

- AI attribution never shifts accountability. The human submitting the PR
  owns every line, must understand it, and must respond to review feedback
  substantively. "The AI wrote it" is not an answer to a review question.

### 8.4 CHANGELOG and docs

- Update the `CHANGELOG.md` of **every package you changed**, under
  `## Unreleased` (replace `*None.*`).
- One concise bullet per change, written for downstream users, not for
  reviewers.
- Do not bump version numbers — releases are handled by maintainers.
- When public APIs change, also update `README.md`, `README-ZH.md`, API
  doc comments, and any affected examples.

### 8.5 Self-review your diff before every commit

Always inspect what you are about to commit:

```bash
git diff                          # unstaged
git diff --staged                 # staged
git diff <base-branch>...HEAD     # full branch diff before opening/updating a PR
```

Remove before committing:

- Debug output (`print`, `debugPrint`, `console.log`, temporary logs).
- Commented-out code left from earlier attempts.
- Reformatting or import re-ordering of files that are not the subject
  of this change.
- Unrelated bumps in `pubspec.yaml` / `pubspec.lock`.
- Whitespace-only changes in unrelated files.
- Editor/OS junk (`.DS_Store`, `.idea/`, personal scratch files).

If you cannot explain why a hunk is in the diff, it does not belong in
the commit. Never use `git add .` or `git add -A` — stage files by path.

### 8.6 Opening the PR

- **Open as a draft PR** (`Create draft pull request`) when the change
  is large, exploratory, or when you want maintainer direction before
  polishing. Convert to Ready for Review once local checks pass and the
  description is complete.
- Reference the closing issue with `Closes #NNNN` in the description.
- Follow the AI attribution rules in §8.3: disclose which agent(s)
  contributed and at which stage.
- Write PR titles and bodies in English, in the same commit style as
  §8.2.
- Only tick a PR checklist item that is genuinely done. For items that
  do not apply, keep the box unchecked and add *(not applicable —
  reason)* next to it. Do not check "done" as a shortcut.
- **Describe verification honestly — no boilerplate "Test plan"
  checklist.** In prose, state what you actually confirmed and how, in
  one or two sentences:

  > *Added 15 unit tests covering method / content-type / custom-header
  > combinations; `melos run test:vm` and `melos run analyze` clean.*

  Mechanical prerequisites (`dart analyze`, `dart format`) are already
  covered by the PR template's top-level checklist — do not re-list them
  as "tests". Behavioral verification means checks that would fail if
  this change regressed.

  If something that ought to be verified genuinely could not be — needs
  browser CI, a physical device, production load, and so on — list it
  under a short **Unverified** paragraph explaining why. Unverified
  items are known risks; this should stay rare, not become routine.

### 8.7 Review iteration workflow

After opening the PR:

- **Address feedback with new commits appended to the branch**, not by
  squash-and-force-push. Maintainers rely on incremental history during
  review; squashing happens at merge time.
- **Avoid `git push --force` on a branch that already has review
  comments** — it detaches those comments from their code position. If a
  rebase is genuinely required (e.g., conflict resolution against
  `main`), leave a comment before pushing so reviewers know.
- **Do not close and reopen the PR** to reset review state, retry CI, or
  bypass a blocking review. Push a fix instead.
- **Design-level feedback is a conversation, not an instruction.** If a
  reviewer's suggestion changes the intent of the PR (not just its
  implementation), reply first and reach agreement before writing new
  code. Blindly applying a large suggestion is worse than discussing it.
- **Mark review threads resolved** only after you have addressed the
  point in code and left a reply explaining what changed — or after the
  reviewer explicitly says so. Do not silently resolve.
- **CI failures**: read the failing job's log, find the root cause, then
  push a fix. Never re-run CI hoping for a green run. If a test is
  genuinely flaky, say so in a comment — do not paper over it by
  disabling the test or adding retries.

### 8.7 Review iteration workflow

After opening the PR:

- **Address feedback with new commits appended to the branch**, not by
  squash-and-force-push. Maintainers rely on incremental history during
  review; squashing happens at merge time.
- **Avoid `git push --force` on a branch that already has review
  comments** — it detaches those comments from their code position. If a
  rebase is genuinely required (e.g., conflict resolution against
  `main`), leave a comment before pushing so reviewers know.
- **Do not close and reopen the PR** to reset review state, retry CI, or
  bypass a blocking review. Push a fix instead.
- **Design-level feedback is a conversation, not an instruction.** If a
  reviewer's suggestion changes the intent of the PR (not just its
  implementation), reply first and reach agreement before writing new
  code. Blindly applying a large suggestion is worse than discussing it.
- **Mark review threads resolved** only after you have addressed the
  point in code and left a reply explaining what changed — or after the
  reviewer explicitly says so. Do not silently resolve.
- **CI failures**: read the failing job's log, find the root cause, then
  push a fix. Never re-run CI hoping for a green run. If a test is
  genuinely flaky, say so in a comment — do not paper over it by
  disabling the test or adding retries.

## 9. Patterns that may lead to closure

Quick cross-reference — each pattern is a violation of the rules above.
PRs matching one or more of these may be closed without detailed review
at the maintainers' discretion.

| Pattern | See |
|---|---|
| No motivation or prior maintainer discussion | §1 |
| Multiple unrelated changes bundled in one PR | §1 |
| Logic changes without effective, non-duplicated tests | §2 |
| Public-API break without maintainer sign-off | §3 |
| Sensitive-area change without maintainer notice | §3 |
| Drive-by dependency bump in a feature/fix PR | §3 |
| Guessed / hallucinated API usage | §4 |
| Drive-by refactors, formatting sweeps, unrelated `.gitignore` / CI edits | §4, §8.5 |
| Branch name not following `category/ticket-id-or-short-description` | §8.1 |
| Non-standard commit message format (missing gitmoji, wrong type, non-English) | §8.2 |
| Missing or hidden AI attribution | §8.3 |
| Debug output or commented-out code left in the diff | §8.5 |
| Falsely checked PR checklist items | §8.6 |
| Force-pushing or close/reopen to reset review state | §8.7 |
