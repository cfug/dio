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
  writing code, unless a maintainer has already asked for it. Feature PRs
  without prior discussion or clear motivation waste both your tokens and
  the maintainers' time, and might be closed.

## 2. Tests are mandatory for logic changes

Every behavioral change must be proven by tests.

- Any change to logic requires new tests or adjustments to existing tests
  that fail without the change and pass with it. Bug fixes must include a
  regression test that reproduces the original report.
- CI reports coverage diffs on every PR. Coverage of changed code must not
  regress; new code paths (including error paths) must be covered.
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
- Never change public method signatures, remove/rename public symbols,
  change default behavior, or alter thrown exception types in a
  non-major release.
- If an API must go away, deprecate first and keep it working:

  ```dart
  @Deprecated('Use XXX instead. This will be removed in 7.0.0')
  ```

  Deprecations state their replacement and the removal version, and are
  only removed in the next major release, together with an entry in
  `dio/doc/migration_guide.md`.
- Do not raise the minimum Dart/Flutter SDK constraint of any package
  unless required by the [Compatibility Policy](COMPATIBILITY_POLICY.md)
  or its listed exceptions. CI tests against the minimum supported SDK;
  do not use language/library features beyond a package's lower bound.
- Watch for **behavioral** breaking changes too: changing defaults, header
  normalization, redirect/error semantics, or timing/ordering of
  interceptors can break downstream even when signatures are untouched.
- If a breaking change is genuinely unavoidable, stop and raise it in an
  issue for maintainers to decide. Do not merge-request it unilaterally.

## 4. Understand before you change

- Read the surrounding code and existing patterns before editing. Match
  the existing style, naming, and module boundaries.
- Fix root causes, not symptoms. When a symptom is reported, locate the
  actual defect before patching.
- Never guess an API — neither dio's internals nor third-party packages.
  Read the actual source (dependencies live in
  `~/.pub-cache/hosted/pub.dev/<package>-<version>/`) and the package's
  own tests/examples when unsure. If `dart analyze` says a member does
  not exist, go back to the source instead of retrying variations.
- Keep diffs minimal. Touch only files required by the change. No drive-by
  refactoring, reformatting of untouched code, dependency bumps, or
  `.gitignore`/CI edits that are unrelated to the stated purpose.

## 5. Production quality only

- No placeholder work: no `TODO`/`FIXME` left behind, no mocked or
  simplified logic presented as complete, no "will optimize later" code.
- Handle edge cases and error paths explicitly; never swallow errors
  silently.
- If you cannot finish something completely, say so explicitly and state
  the boundary — do not pretend it is done.

## 6. Repository layout and workflow

This is a [Melos](https://melos.invertase.dev) mono-repo:

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

## 7. Changelog, commits, and PR hygiene

- Update the `CHANGELOG.md` of **every package you changed**, under the
  `## Unreleased` section (replace `*None.*`). One concise bullet per
  change, written for downstream users. Do not bump version numbers —
  releases are done by maintainers.
- Write commits and PRs in English. Keep the PR title in the repository's
  existing style (see `git log`), and reference the related issue.
- Fill in the PR template truthfully. Check the docs when public APIs
  changed (`README.md`, `README-ZH.md`, API docs comments, examples).
- Agent-assisted PRs are welcome, but the human submitting the PR owns it:
  you must understand every line, be able to defend it in review, and
  respond to review feedback substantively. "The AI wrote it" is not an
  answer to a review question.

## 8. Patterns that may lead to closure

To keep maintainer time for well-cared contributions, PRs exhibiting these
patterns might be closed without detailed review:

- Feature dumps with no stated motivation or prior discussion.
- Multiple unrelated changes bundled together.
- Logic changes without tests, or with tests that assert nothing.
- Unrelated file churn (formatting sweeps, `.gitignore`, CI, docs
  restructuring smuggled into a functional PR).
- Falsely checked checklist items (e.g. claiming tests ran when they
  did not).
- Breaking public API changes without prior maintainer sign-off.
