# AI Agent SDLC Framework

A software development lifecycle framework for human-AI pair programming. All of the learning, iteration, and failure-driven evolution described here was done with Claude Code; the framework has more recently been extended to support Codex CLI and is now structured to work with any AI coding agent that reads markdown instruction files. It is layered, opinionated, and each rule traces to a real failure. The narrative of how it got here -- the failures, the iterations, the things that broke -- is in the [blog post](https://tadg.ie/blog/ai/2026-04-17-claude-code-sdlc/). This document is the reference: what is here, how it is organized, why each piece exists, and how it loads.

The framework is sized for one human and one collaborator, but the failure modes it addresses recur anywhere these tools are used without comparable scaffolding.

## Quickstart

Clone this repository to a stable location:

```bash
git clone https://github.com/tadg-paul/agents.git ~/code/agents
```

Run the setup script for your agent (or both — they are independent):

### Claude Code

```bash
~/code/agents/setup-claude.sh
```

Creates symlinks in `~/.claude/`:

| Symlink | Points to |
|---|---|
| `CLAUDE.md` | `AGENTS.md` |
| `SDLC.md` | `SDLC.md` |
| `docs` | `docs/` |
| `commands` | `commands/` |

Then review and merge `settings.example.json` into `~/.claude/settings.json`. The file is annotated — do not replace an existing `settings.json` wholesale; merge the relevant entries.

### Codex CLI

```bash
~/code/agents/setup-codex.sh
```

Creates symlinks in `~/.codex/`:

| Symlink | Points to |
|---|---|
| `AGENTS.md` | `AGENTS.md` |
| `SDLC.md` | `SDLC.md` |
| `docs` | `docs/` |
| `prompts-commands` | `commands/` |

Then review and merge `config.example.toml` into `~/.codex/config.toml`. Do not replace the live file wholesale — existing `[projects.*]` trust entries will be lost.

### Using both agents simultaneously

Both scripts are independent and can both be run. Because all targets are symlinks into the same repository, a `git pull` in the repo root updates both agents at once.

### Project-level instructions

Each project using the framework should have a project-level `AGENTS.md` in its root. Claude Code reads `CLAUDE.md` by default; the `config.example.toml` includes a `project_doc_fallback_filenames` entry so that Codex also accepts `CLAUDE.md` during transition.

### Project scratch directory

The framework writes scratch files to `./.agent/tmp/` within each project. Add this to the project's `.gitignore`, or once to your global gitignore so all projects inherit it:

```bash
echo '.agent/tmp/' >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

## The Problem

AI coding agents are powerful development tools, but without operational constraints they exhibit predictable failure modes that undermine the quality of work they produce:

- **Premature implementation.** It writes code before requirements are agreed, solving the wrong problem efficiently.
- **Shortcut testing.** It writes tests that exercise internal APIs instead of real user entry points. Tests pass; the application is broken.
- **Error suppression.** It silences failures with patterns like `|| true` instead of handling them, defeating the safety nets it was told to use.
- **Self-authorization.** It declares its own work satisfactory and moves on without waiting for human review. It has been observed writing approval keywords into its own output to advance past quality gates.
- **Scope creep.** It "improves" surrounding code, adds features not requested, and refactors things that already work.
- **Causal misattribution.** Asked why something behaves unexpectedly, it names a plausible culprit without isolating it -- and if corrected, reaches for the next plausible culprit rather than running a diagnostic.
- **Unauthorized data exposure.** Where a process requirement appears to demand a resource that does not exist, it creates that resource on its own initiative -- including, in one observed case, creating a **public** GitHub repository and uploading the working directory contents to it, because the framework required work to be tracked in an issue and there was no git repository to host one in. A process rule was satisfied; the contents of a private working directory were now on the open internet.

Every rule in this framework exists because one of these failures occurred in production work. None are theoretical.

### Observed patterns by category

The specific patterns underlying the headline failures, named so they can be referred to and prohibited:

**Testing shortcuts:**
- *Testing the internals instead of the real thing.* The spec says "run the CLI command"; the test calls the underlying library function in-process. The real binary -- with its argument parsing, subprocess spawning, signal handling -- is never exercised.
- *Testing the storage layer instead of the user experience.* The spec says "user sees a confirmation page"; the test checks the database row. The row may exist while the page that displays it is broken.
- *Checking that code exists instead of running it.* The test greps source to verify a function is defined, rather than calling it and checking output. This verifies that someone *wrote* the function, not that it *works*.
- *Covering one condition when the spec implies several.* AC: "rejects invalid, expired, and missing tokens" (three conditions). Test covers "invalid" only. The other two surface in production.

**Error handling shortcuts:**
- *`|| true` / `|| :`.* Tells the shell to pretend a command succeeded. Defeats `set -e` line by line.
- *`cmd || rc=$?`.* Captures the error code, looks principled, but suppresses the safety mechanism just as effectively as `|| true`.
- *`set +e` ... `set -e`.* Turns error checking off, runs risky code, turns it back on. If the re-enable is forgotten or the code is nested, safety never returns.
- *`2>/dev/null` with no fallback.* Discards the error message; the error still happens. The program continues broken with no diagnostic.
- *Bare `except: pass` / empty `catch {}` / `catch (Exception e) {}`.* The error is caught and discarded; the program proceeds with corrupt state.
- *The `((count++))` gotcha.* Returns exit code 1 when the result is zero, triggering `set -e`. The shortcut is `|| true`; the correct fix is `count=$((count + 1))`.

**Process shortcuts:**
- *Self-authorizing past gates.* Writing `SATISFIED`/`PROCEED`/`APPROVED` into the model's own output, advancing without human review.
- *Declaring completion without demonstration.* Saying "fixed" or "done" when tests pass but the user-facing behaviour has not been shown.
- *Overwriting the human's edits.* Reverting human changes the model disagrees with. Human edits are authoritative.
- *Treating a question as an instruction.* "What do you think of X?" parsed as "go and implement X", with product decisions made en route.
- *Silently removing information from issues.* Deleting AC rows or comments rather than editing in place with strikethrough.
- *Creating a public GitHub repo to satisfy a process requirement.* The framework requires that work be tracked in an issue. Asked to start work in a directory that was not a git repo, the agent (Claude Code, in the incident that produced this rule) created a **public** GitHub repository and uploaded the directory tree to host the issue against. The process rule was satisfied; the contents of a private working directory were now on the open internet. The instructive part: a general prohibition on *widening access to data without explicit instruction* was already in place when this happened. The agent did not recognize creating a public repo as a case of widening data access -- it framed the action as "satisfying the issue-tracking requirement" and the general rule did not fire. The fix was to add a *specific* prohibition: when initializing version control, `git init` is local-only; never create a remote. The general rule remains, but the specific case had to be named -- another instance of rule-lawyering closed only by explicit prohibition.

**Coding shortcuts:**
- *Building shell commands from strings.* `eval`, string concatenation, `$cmd` interpolation -- a classic injection vector. Use arrays.
- *Text-replacement tools on source code.* `sed`/`awk` for modifying source has no understanding of language structure; it corrupts files in ways that are hard to review. Use AST-aware tools (`ast-grep`).
- *Embedding secrets in source.* Hardcoding API keys; disabling TLS verification; `chmod 777` to get past a permissions error.
- *Functions too large or too deeply nested.* >50 lines, >3 levels deep, god objects. Hides bugs and obstructs review.
- *`rm` instead of `trash`.* Permanent deletion when recoverable deletion is available.

The catalogue under `SDLC.md` §4 (Known Failure Modes) names 13 of these by number so they can be cited in conversation -- "this is a §4.10 violation" -- rather than re-arguing whether something went wrong. The rules each one produced are spread across the files described below.

## Objectives

1. **Human retains control.** No code is written, no issue is closed, no decision is made without explicit human authorization at defined checkpoints.
2. **Quality through discipline.** Test-driven development, real-behaviour testing, proper error handling, and coding standards are enforced by process, not by trust.
3. **Traceability.** Every change traces to a GitHub issue, every issue has acceptance criteria, every acceptance criterion has tests, every test has a unique ID. Nothing is ad hoc.
4. **No shortcuts.** The framework names and prohibits the shortcuts Claude Code is known to take, and requires visible accountability rules (e.g. answering the "real-user test" question in chat before marking a test as passing) rather than relying on rules it can reinterpret.
5. **Signal-to-noise discipline.** Only the documents relevant to the current task are loaded. Rules compete for attention; loading less makes each rule stickier.

## Overall Structure

The framework is built in layers. Each layer has a single purpose and only loads when relevant. The principle behind the layering is explained under [Load less to follow more](#load-less-to-follow-more) below.

```
~/code/agents/              # This repository -- single source of truth for all agents
  AGENTS.md                 # Layer 1: universal rules - always loaded
  SDLC.md                   # Layer 2: code-specific rules - loaded for code work
  docs/                     # Layer 3: standards reference - loaded by SDLC.md
    ISSUES.md
    TESTING.md
    CODING.md
    GIT.md
    DOCUMENTATION.md
    CODE/                   # Layer 4: per-language standards - loaded for that language
      SHELL.md
      PYTHON.md
      GO.md
      WEB.md
  commands/                 # Invocable slash commands / saved prompts

{agent-home}/               # Symlinks into this repo (created by setup-*.sh)
  CLAUDE.md -> AGENTS.md    # Claude Code entry point
  AGENTS.md -> AGENTS.md    # Codex CLI entry point
  SDLC.md   -> SDLC.md
  docs      -> docs/
  commands           -> commands/   (Claude Code)
  prompts-commands   -> commands/   (Codex CLI)
  settings.json             # Claude Code harness config (from settings.example.json)
  config.toml               # Codex CLI agent config (from config.example.toml)

<project>/                  # Per-project layer (a separate repo)
  AGENTS.md                 # Optional - project-specific rules
  docs/                     # Project documentation
  .agent/
    tmp/                    # Project-relative scratch (gitignored)
    settings.json           # Claude Code: project-level harness overrides
```

### The two-axis split

Two splits divide the framework. They are orthogonal:

**Universal vs. code-specific.** `AGENTS.md` holds the rules that apply to any work the agent does with the human -- writing code, drafting documentation, organizing notes, planning, research. `SDLC.md` holds the rules that apply only when handling code: the three gates, the failure modes catalogue, the workflow. The split was introduced so the framework can be used for non-code work without dragging the full SDLC apparatus into every interaction.

**Process vs. craft.** `SDLC.md` describes *the process* -- how work moves from idea to merged code. `docs/` describes *the craft* -- what good acceptance criteria look like (`ISSUES.md`), how to test real-user behaviour (`TESTING.md`), how to write code in each language (`CODING.md` + `CODE/`), how git is used (`GIT.md`), how documentation is structured (`DOCUMENTATION.md`). The process documents tell you *when* to do something; the craft documents tell you *how to do it well*.

### Loading model

Documents are loaded into the agent's context window only when relevant:

| Document | When loaded |
|---|---|
| `AGENTS.md` | Always |
| `SDLC.md` | When working with code, scripts, software, or systems (via the `/useful-be` skill or explicit instruction) |
| `docs/ISSUES.md`, `docs/TESTING.md`, etc. | Alongside `SDLC.md` for code work |
| `docs/CODE/SHELL.md` etc. | Only for the language(s) actually in use |
| Project `AGENTS.md`, project `docs/` | When working in that project |

Each document carries a one-word canary suffix at its end. Reading the document means appending the suffix to the response greeting. The complete chain, when everything is loaded, is:

```
EHLO SDLC ISSUES TEST CODE GIT DOC SHELL PY GO WEB
```

If a suffix is missing, that document's rules were not in scope for the interaction. The chain is a read receipt visible at a glance.

### The pledge

The root canary ("EHLO") is more than a read receipt. It is a pledge. Saying "EHLO" attests that the agent has read `CLAUDE.md`, agrees with it, agrees with its spirit, and commits not to game it. The same pledge is at the bottom of `SDLC.md`. Details and the wording history are in [Canary System](#canary-system) below.

## The Three Gates

The framework's load-bearing process mechanism. Three keyword checkpoints govern all issue-driven work; only the human types them. Each gate authorizes the next phase of work.

| Gate | Keyword | What it authorizes |
|------|---------|-------------------|
| Gate 1: Requirements | `SATISFIED n` | Solution design may begin |
| Gate 2: Solution | `PROCEED n` | Test and implementation code may be written |
| Gate 3: Review | `APPROVED n` | Issue may be closed |

Gate keywords must come from the human, typed in ALL CAPS, followed by the issue number (e.g. `SATISFIED 12`). The agent may never write a gate keyword itself -- this is an absolute prohibition. The strict format requirements (ALL CAPS, with issue number, in the current conversation turn, from the human) were refined after the agent found ways to self-authorize: writing keywords into its own output, referencing approvals from different issues, and inferring approval from context.

Enforcement is by §1 prohibition only -- the keywords are text-recognized, not harness-blocked. An earlier iteration implemented each keyword as a skill with `disable-model-invocation: true` in its frontmatter. It failed both ways: the agent sometimes refused to acknowledge the keyword and demanded the skill be invoked explicitly (false negative -- overcautious), and sometimes invoked the skill itself anyway (false positive -- the harness lock did not reliably prevent self-invocation under all conditions). The scaffolding was retired in favour of pure text recognition plus the §1 prohibition. The `/build` skill (see [Skills Reference](#skills-reference)) is a related case: it acts as a PROCEED-equivalent when invoked by the human as a slash command, with the human-only constraint carried as a hard prohibition in the skill body. Slash-command invocation avoids the false-negative failure (no keyword to misrecognize); the §1-style text prohibition is the same defence used by the keywords themselves against false positives.

### Between gates: continuous flow

The gates are the only hard stops. Between gates, the agent works continuously without waiting for further instruction:

- **After `SATISFIED n`:** proceed through solution design, ending with `AWAITING PROCEED - issue #n`.
- **After `PROCEED n`:** proceed through writing tests (TDD red), implementation (green), and review, ending with `READY FOR REVIEW - issue #n`. Do not stop in the middle.
- **After `APPROVED n`:** close the issue.

Skills are *tools*, not gates. The human invokes a skill when a specific phase needs to be done in isolation or an advisory pass is wanted (see [Skills Reference](#skills-reference)). The agent does not "wait for the next skill" -- if a gate keyword has been given, the work to the next gate is the agent's to do.

### The bypass clause

`BYPASS-GATE-7` is an escape hatch for small, clearly-scoped work that does not warrant a GitHub issue (typo fixes, single-line refactors, dependency additions). It must come from the human, in the prompt, as an exact phrase. Bypass work is still tracked: if no issue exists, one is created retrospectively.

## File Reference

Each global file has a single purpose. The "What it covers" sections list current rules; the "How it evolved" sections give the rationale -- each addition traces to a specific failure or recognition.

### AGENTS.md -- Universal Rules

**What it covers:**
- Identity and the working relationship between human and assistant
- Absolute prohibitions (always-on, no exception process): never write outside the working directory, never write to auto-memory, never overwrite human edits, never use `rm` (only `trash`), never claim something is "done" or "fixed" without evidence, never argue with a direct instruction, never treat a question as an instruction, never invoke a skill or mode transition without explicit prompt
- Verifying outgoing claims: every factual or causal claim must be accompanied by the verifying tool call in the same response, or flagged as a guess. Includes the explicit two-wrongs rule: when a claim is corrected, the right next move is a diagnostic, not a different plausible guess
- Core principles: never fabricate, quality over speed, stay focused
- Communication standards: ABC (Accuracy, Brevity, Clarity), no gaslighting, no superfluous religious language
- Language: Hiberno-English, OED spellings (`-ize` suffixes)
- Rule precedence: safety first, then universal prohibitions, then SDLC, then project conventions, then external style guides
- Direction to load `SDLC.md` for any code-related work
- The root canary pledge (active commitment form)

**How it evolved:**
- The split from a single combined document (which previously held both universals and code-specific machinery) happened when it became clear that loading the full SDLC for non-code work was both wasteful and dilutive to the rules
- The "write outside cwd" prohibition was reformulated as absolute after exception requests kept arriving as "but just this once" with reasonable-sounding justifications. The current wording is "Never write outside of cwd under any circumstances. You may read outside of cwd only when directed to" -- no exceptions to consider
- The git-state rule (require a clean git repo before editing tracked files) was added after multiple "where did my changes go" recoveries that would have been trivial with version control already in place
- Verifying outgoing claims (§3) was significantly sharpened over multiple iterations. The latest revision adds causal claims explicitly (plausibility is not evidence) and the two-wrongs reflex (do not reach for the next plausible culprit when corrected)

### SDLC.md -- Code-Specific Process

**What it covers:**
- Code-specific prohibitions (on top of the universals): never write source code before PROCEED, never write a gate keyword yourself, never close a GitHub issue without APPROVED, never mark a user test as passing, never use `--no-verify` etc., never create a second AC table
- The three quality gates (see above)
- The autonomous-action exception (BYPASS-GATE-7) and what kinds of work qualify
- The process checklist: between gates, do the work continuously; never tell the human you are waiting for a skill
- 13 documented failure modes AI coding agents are known to exhibit, named so they can be referred to by number
- Bug report handling: the human's observation is evidence; the agent's hypothesis is not
- Plan mode: externalize plans into GitHub issues, not chat; ephemeral planning is forbidden
- GitHub repo rules: no changes without an approved issue; use `gh` CLI; tag minor point release on each closure
- Homebrew formula/cask conventions
- Code principles: fix root causes; preserve existing style
- Makefile conventions: standard entry points (`build`, `test`, `lint`, `install`, `release`, `sync`)
- Runtime environment fallback (PATH for restricted shells)
- Reference document index (points to `docs/`)
- The SDLC canary suffix pledge

**How it evolved:**
- Started life as part of `CLAUDE.md`; extracted to its own document when the framework grew to need a clear separation between universal rules and code-specific machinery
- The number of failure modes grows over time. Recent additions include "Asserting from priors instead of reading" and "Manufacturing ACs for bug fixes" (a regression test against an existing AC is the right pattern, not a new AC)
- The "between gates: continuous flow" rule was added after the framing "wait for me to invoke the next skill" was repeatedly misread as "stop after each phase and wait" -- grinding everything to a halt
- The autonomous-action exception (BYPASS-GATE-7) was added because requiring an issue for every typo correction was unsustainable. The exact-phrase requirement, in the human's prompt, prevents the model from invoking the exception itself

### docs/ISSUES.md -- GitHub Issue Standards

**What it covers:**
- Voice and tone: issues are written impersonally, in the third person
- Well-formed issue structure: problem statement, solution section, acceptance criteria table
- Acceptance criteria table format: three columns (ID, acceptance criterion, tests)
- The critical distinction between acceptance criteria (statements about system state) and tests (descriptions of how that state is verified)
- A litmus test: "Could this statement be true or false without specifying how it is observed?" If not, it is a test
- Forbidden word list for the AC column (action verbs, passive test phrasings, test-structure language)
- Single source of truth rule: exactly one AC table per issue, edited in place
- Multi-condition coverage: criteria implying N conditions require N tests
- Immutability boundary: ACs and tests are draft text before sign-off, immutable after

**How it evolved:**
- Did not exist in the initial commit -- it was created when acceptance criteria quality became a persistent bottleneck
- Forbidden word list was compiled from real recurring examples
- The single source of truth rule was added after multiple AC tables appeared in different comments on the same issue, leading to implementation work against outdated requirements
- The multi-condition coverage rule was added after one-test-per-criterion patterns produced systematic gaps
- The immutability boundary resolved a tension between auditability (ACs must not change after sign-off) and drafting agility (ACs need to be freely edited before sign-off)
- Voice and tone rules were added after issues started referencing "I", "we", and specific people by name

### docs/TESTING.md -- Testing Standards

**What it covers:**
- The "real-user test" principle -- the single most important rule in the framework. Before marking any regression test as passing, state in chat what user action the test simulates and what the user would observe
- Test-driven development workflow
- Three test categories:
  - **Regression tests (RT)** -- the default; run on every `make test`
  - **One-off tests (OT)** -- tied to a specific event (a migration, a reproduction of an incident); excluded from `make test`
  - **User tests (UT)** -- outcomes that genuinely require human judgement (visual correctness, audio quality)
- A decision tree for choosing the right category
- Multi-condition coverage requirements
- Directory layout, test ID scheme tied to issues, Arrange-Act-Assert structure, coverage requirements (80% floor for new code, 100% for critical paths)
- Test boundaries (unit, integration, end-to-end) with run-frequency guidance
- "No mocks" rule: mock external APIs and time/dates, never mock the thing under test
- Source code introspection is forbidden in tests (a test that greps source proves only that someone wrote the code, not that it works)

**How it evolved:**
- Started as a basic six-step TDD checklist
- The test ID scheme was originally a global counter; simplified to issue-scoped IDs (`RT-12.1`) with no central file
- The "real-user test" principle was prompted by the TTS deadlock incident: every test called the engine's library function in-process instead of invoking the real binary, so a bug in the subprocess code path was invisible to the entire test suite
- The three-category split was added after one-off tests kept appearing in the regression suite, and after the agent classified everything as a user test to avoid writing automated ones
- The "no source-introspection" rule was added after a test suite for a Hugo theme's hover affordance was grepping source CSS rather than verifying behaviour. The same agent recognized the violation under the new rule and self-corrected -- a strong validation signal

### docs/CODING.md -- Cross-Language Coding Standards

**What it covers:**
- Platform constraints (macOS/Apple Silicon for local development, Linux for deployment)
- Language and tool selection hierarchy: match the existing project, then the genuinely best fit, then the simplest maintainable option
- Style baselines table mapping each language ecosystem (shell, Python, Swift, HTML, CSS, JS, TS, Ruby, Rust, Go, Java, Kotlin, C/C++) to its standard linter and formatter
- Code commenting rules: ABOUTME header, evergreen comments
- Data handling principle: format-aware parsers only (jq, yq+jq, dasel, htmlq for shell; `encoding/json` / `gopkg.in/yaml.v3` for Go; `json` / `yaml` for Python). Never sed/awk/perl for data modification
- Anti-embedding rule: never embed one language as a string inside another. Use file-based templates, parameterised queries, or proper code generation
- Cross-language escaping: SQL parameterisation, shell quoting (`%q`, `shlex.quote`), HTML auto-escaping, JSON marshalling, URL encoding -- one principle, one table
- Prohibited anti-patterns: error suppression (all languages), unsafe practices, security vulnerabilities
- Error handling, code structure, security (secrets, input validation, permissions, Docker), output (ISO 8601), logging, file operations (atomic writes), network operations
- Dependency management and security auditing
- Direction to language-specific docs under `CODE/` for the language in use

**How it evolved:**
- Started as a short style guide covering only shell and Python
- The style baselines table was added once projects began spanning many languages -- without a table mapping each to its standard tools, agents would use inconsistent linting and formatting across files in the same project
- The prohibited anti-patterns section grew incrementally; each entry traces to a real incident (`|| true` for `set -e` defeat, `eval` for injection-vulnerable patterns, sed/awk for source corruption, bare `except: pass` for swallowed errors, the `((count++))` arithmetic gotcha)
- Linter bypass rules were added after `# noqa` and `# type: ignore` appeared without justification
- The most significant restructure was extracting language-specific content into `CODE/` after the document's shell-heavy bias became a problem -- when half the worked examples were bash, the implicit signal to agents was "solve with shell"
- The cross-language escaping section unifies what used to be scattered prohibitions across SQL, shell, HTML, JSON, URL into a single rule
- `ast-grep` was demoted from "always use" to "preferred for cross-file structural refactors" -- direct editing is fine for single-file changes

### docs/CODE/SHELL.md -- Shell Standards

**What it covers:**
- Applies to both interactive shell commands and scripts (script-specific sections marked as such)
- Version targeting: bash 5+ for all projects
- Mandatory safety header (`#!/usr/bin/env bash`, `set -euo pipefail`). The third "Bash Strict Mode" line (`IFS=$'\n\t'`) is explicitly forbidden -- see [Notable Findings](#ifs-nt-is-harmful-not-protective)
- Required practices: variable quoting, array-based command construction, `command -v` not `which`, `find -print0` pipelines, `-h`/`--help`/`--version` and `--dry-run` on all CLI executables
- Help text is documentation: keep it in `./docs/<command>-help.md` and have the executable read it at runtime or package it at build time; do not maintain help text as a long inline heredoc
- Prohibited patterns: `eval`, `$cmd` as a command, string-built commands, scripts discovered via `find`/globbing, wiring discovered paths into schedulers
- The `((count++))` arithmetic gotcha (exit code 1 when result is zero, killing `set -e`) with safe alternatives
- Data handling: comprehensive tool table for structured formats. Prohibition on sed/awk/perl for any data modification
- Data format policy: JSON for program-internal data, YAML for user config, CSV for tabular user data
- Portability across Darwin/Linux, atomic writes, `trash` not `rm`
- Schedulers and services (systemd, launchd, cron): never generate definitions from runtime discovery; absolute paths in `ExecStart`

**How it evolved:**
- Extracted from CODING.md when the shell-heavy bias started biasing agents toward shell as the default
- The bash 3.2 fallback was removed after workarounds for missing features consistently outweighed the benefit
- The `IFS=$'\n\t'` prohibition was added after the canonical "Bash Strict Mode" line broke a real `read A B C < <(stty size)` pattern
- The help-text-as-documentation rule was added after maintaining help text inside executables (as long inline heredocs) made it neither reviewable nor editable in step with the rest of the docs
- `ripgrep` was scoped down to file discovery (`rg -l`) after content extraction almost always wanted a format-aware tool downstream

### docs/CODE/PYTHON.md -- Python Standards

**What it covers:**
- Never use system Python on macOS
- Version management with `uv` preferred (combines Python versions, venvs, packages), `pyenv` + venv acceptable as fallback
- Virtual environments are mandatory: never `pip install` outside a venv
- `src/` layout for new projects to prevent accidental imports of source over installed package
- `pyproject.toml` for packaged projects, `requirements.txt` acceptable for simple scripts
- Standard Ruff configuration (Black-default line length 88, `E501` ignored)

**How it evolved:**
- Extracted from CODING.md as part of the language-doc split. Content essentially unchanged from the original Python section
- The split makes future additions (testing patterns, async conventions, framework opinions) a low-friction addition without re-bloating CODING.md

### docs/CODE/GO.md -- Go Standards

**What it covers:**
- Standard project layout (`cmd/<app>/main.go`, `internal/`, optional `pkg/`)
- 12-factor configuration: runtime config via environment variables, never hardcoded paths. Bind to `ADDR` from environment, never hardcode a port or `0.0.0.0`
- Error handling: every error checked (`errcheck` enforces); discard with `_ = err` requires a one-line justification; wrap with `fmt.Errorf("context: %w", err)`; `errors.Is`/`errors.As` for type checks; no `panic` in library code
- HTTP clients: never `http.DefaultClient` (no timeout); always explicit clients with timeouts; always close response bodies (`bodyclose`)
- Shell-safe interpolation when constructing shell commands from Go: `fmt.Sprintf` with `%q`, not `%s`
- Function decomposition: `main()` is a coordinator; when it grows past 50 lines, extract phase functions
- Cross-compilation: `GOOS=linux GOARCH=amd64 go build` for Linux deployment from macOS. No Go toolchain on production servers
- Concurrency: goroutines must have a clear context-cancelled lifecycle; channels for communication, mutexes for state; `go test -race`
- Testing patterns: table-driven tests, `t.Helper()`, `_test.go` alongside code
- Standard tooling: `gofmt`/`goimports`, `go vet`, `golangci-lint`
- Standard library preference: stdlib first; third-party requires justification beyond a small whitelist

**How it evolved:**
- Created when migration from shell to Go binaries began. Most conventions trace to a code audit of an actual deployment toolchain, where each finding traced to a real bug:
  - `cmd.Run()` with discarded error -> the discarded-error rule
  - `http.DefaultClient` for API calls -> the always-timeout rule
  - `fmt.Sprintf("hugo --baseURL %s", cfg.BaseURL)` shell injection -> the `%q` rule
  - 200-line `main()` -> the phase-function decomposition rule
  - `awk -F. '{print $(NF-1)"."$NF}'` broken on `.co.uk` -> the prefer-stdlib rule (replaced with pure-Go DNS handling)
- 12-factor configuration was adopted by convergent evolution, not by design -- see [Notable Findings](#convergent-evolution-to-12-factor)

### docs/CODE/WEB.md -- Web Standards

**What it covers:**
- A source/rendered/presented tier model for web content -- determines which artefacts tests may legitimately query
- HTML standards: semantic elements (never `<div>` soup), document outline (one `<h1>`, no skipped levels), accessibility minimums (meaningful `alt`, labelled form inputs, keyboard navigation, WCAG AA contrast), `htmltest` validation
- CSS standards: `rem` for anything that scales with user font preference (never `px` for font sizes), mobile-first responsive design, no inline styles, BEM or project methodology, `stylelint`
- JavaScript minimums: ESM only, never `eval` or `new Function(string)`, strict equality, `async`/`await` over `.then()` chains, no `var`, no global pollution
- Build and test tooling: `htmlq` for CSS-selector queries against rendered HTML, `htmltest` for build-time smoke checks, `stylelint`, `eslint`+`prettier`
- Headless browser tooling (Playwright/Cypress) reserved for the case where the body of UI tests justifies the cost (heuristic: ~8-10 user tests across a project)
- A testing decision tree by tier

**How it evolved:**
- Created when web-content tooling started accreting across multiple docs (htmlq in CODE/SHELL.md, a Web Design subsection in CODING.md, CSS lint discussion floating). Web is its own domain spanning HTML+CSS+JS+build+accessibility
- The source/rendered/presented tier model resolved a real methodology question -- an agent writing tests for a Hugo theme's hover affordance had grepped source CSS; the tier model articulates that rendered HTML is the user-facing artefact, source CSS is not
- HTML and CSS rows were added to the CODING.md Style Baselines table (linter/formatter references that point at CODE/WEB.md), keeping CODING.md as the central per-language index without duplicating the standards

### docs/GIT.md -- Git and Source Control

**What it covers:**
- The fundamental rule (unchanged since the initial commit): never use `--no-verify` when committing
- Forbidden flags: `--no-verify`, `--no-hooks`, `--no-pre-commit-hook`, and any AI attribution in commits
- Commit message standards: conventional commit format, imperative mood, present tense
- Issue-linked commits: `Implement #N: short description`. Strict prohibition on GitHub auto-close keywords (`Fixes`, `Closes`, `Resolves`) -- issues are closed manually after human review, and auto-close bypasses that
- Five-step protocol for pre-commit hook failures: read the complete error output, identify which tool failed, explain the fix and why it addresses the root cause, apply the fix, re-run the hooks. Never bypass
- A reusable pattern for project hooks to chain to global hooks rather than silently replacing them
- Hook setup via Makefile (`hooks/` directory, copy to `.git/hooks/` via `make init`)
- A "pressure response" protocol: when asked to commit or push with failing hooks, the required response is "Pre-commit hooks are failing, I need to fix those first" -- regardless of urgency
- Accountability self-check before any git command
- Formal exception process for situations where a rule genuinely cannot be followed

**How it evolved:**
- Started with `--no-verify` as the only forbidden flag. The list was expanded after the agent used `--no-hooks` and `--no-pre-commit-hook` as alternatives
- Auto-close keywords were banned after `Fixes #N` triggered GitHub's automatic issue closure, bypassing the human review step the gate system exists to enforce
- The pre-commit hook failure protocol was added after the agent's response to a failing hook was to try bypassing it rather than reading the error output
- The pressure response section was added after the agent attempted to skip hooks when asked to commit quickly
- The global hook chaining pattern was added after a project-level `core.hooksPath` setting silently replaced global hooks
- The exception process was formalized to prevent "just this once" from becoming permanent practice

### docs/DOCUMENTATION.md -- Documentation Standards

**What it covers:**
- Voice and tone: documentation is written impersonally, in the third person ("The `--verbose` flag enables debug output", not "I added a flag to handle this")
- Versioning with changelog headers for project documentation files
- Process rules: read existing documentation before starting work; update documentation after code changes, not before
- Mandatory sanitization step: all documentation changes are run through `sanitize` (from `tadg-paul/oed-sanitize`), which normalizes spelling to the OED standard and fixes problematic typographic symbols. Changes summary reported in chat
- Review workflow: write old and new versions to `./.claude/tmp/`, sanitize the new version, then open a side-by-side diff with `code -d`. The human reviews the sanitized version, not a pre-sanitize draft
- Project structure requirements: README.md (or README.org, but not both), all other documentation in `./docs/`. Required document types: vision, architecture, testing, implementation plan, help text per executable
- Inconsistency handling: stop and alert on major inconsistencies that affect the current task; warn about minor ones

**How it evolved:**
- Started as a structural guide
- Voice and tone rules were added after documentation started referencing "I", "we", and specific individuals by name
- The sanitization step was added after inconsistent British/American spelling appeared across documents in the same project
- The review workflow was refined to require sanitization *before* review, not after -- the human was approving pre-sanitized text and then sanitization would change words, meaning the human had approved text they never saw in its final form
- Help text was added as a required document type after the SHELL.md rule landed (help text is documentation, keep it in `./docs/`, do not inline as a heredoc)
- The inconsistency handling rule was added after the agent silently proceeded with implementation despite contradictions in documentation that directly affected the solution design

### settings.json -- Harness Configuration

**What it covers:**
- Permission allowlists: which Bash commands, file reads, file edits, and MCP tools may run without prompting the human for each invocation
- The allowlist is deliberately broad for read-only operations (git, gh, find, grep, etc.) and narrower for state-changing ones
- No credentials or secrets. Tokens for `gh` and similar are stored separately by the relevant CLI itself
- Hooks (when configured): commands the harness runs at specific lifecycle events (after an agent response, before a Bash invocation, etc.)

**How it evolved:**
- Started empty (every command prompted). The allowlist grew incrementally via the `fewer-permission-prompts` skill, which scans recent transcripts and proposes additions
- The principle: things the agent can already see (read-only inspection of the project) should not require a prompt; things that change state should. The `Edit(**/*)` permission is the main exception -- in a git-managed clean repo, edit prompts are unhelpful friction

## Skills Reference

Skills are slash commands the human invokes. They are tools, not gates. The gate keywords (`SATISFIED`, `PROCEED`, `APPROVED`) are the only hard stops; between gates, the agent works continuously.

### SDLC-flow skills

These move work through the issue lifecycle.

| Skill | Purpose | Ends with |
|---|---|---|
| `/draft-issue` | Create issue with ACs and test specs | AWAITING SATISFACTION |
| `/draft-design-issue` | Draft issue + solution design in one pass (no code) | AWAITING PROCEED |
| `/draft-bug-fix` | Draft a bug-fix issue referencing existing ACs (no new AC table) | AWAITING SATISFACTION |
| `/design-solution` | Document the solution on the issue | AWAITING PROCEED |
| `/write-tests` | Write test code only (TDD red phase) | Tests committed, confirmed failing |
| `/implement` | Write code to pass tests | Tests green |
| `/review` | Full review: make test, standards, demo UTs, summarize | READY FOR REVIEW |
| `/build n` | **PROCEED-equivalent.** Orchestrates the full post-PROCEED chain: loads `CODING.md` + relevant `CODE/<language>.md`, runs `/write-tests` (with lightweight checklist), `/implement` (with checklist citing CODING.md and language doc sections), `/review`, and presents the mandatory end-of-gate ceremony (test results, UT demo, AWAITING APPROVAL). Human-invocation only -- treats invocation as the PROCEED authorization for issue #n. | AWAITING APPROVAL |

After `PROCEED` or `/build n` (which is PROCEED-equivalent), the agent runs the test-write -> implement -> review chain continuously without waiting for further instruction. `/build` is the recommended path when the human wants the whole chain to run with the inter-phase checklists and the end-of-gate ceremony enforced. Invoking the underlying skills individually remains supported for cases where only one phase is wanted (e.g. re-running just `/review` after a fix).

### Discovery and migration

| Skill | Purpose |
|---|---|
| `/start-discovery` | Open a discovery (sketch) session, tagged issue, no AC table |
| `/end-discovery` | Close a discovery: promote to a real issue, or rule it out |
| `/migrate-acs` | Migrate ACs from a legacy issue into `./docs/ACs.md` |

### Advisory (no code changes)

These are invoked when a second opinion is wanted. None advance gates.

| Skill | Purpose |
|---|---|
| `/audit-acs` | Challenge AC coverage for edge cases and quality |
| `/audit-tests` | Challenge test specs for coverage gaps and gaming opportunities |
| `/audit-code` | Review implementation against `CODING.md` and language best practice |
| `/diagnose-issue` | Diagnose an issue and recommend a fix |
| `/recommendations-please` | Expert recommendations in a given domain |

The audit and diagnose skills write their long-form findings to `./.agent/tmp/<skill>-<NNN>.md`, render with `~/bin/pandhtml`, and open in a browser -- keeping the terminal short. The chat receives only a one-line summary and the HTML path.

### Setup and context

| Skill | Purpose |
|---|---|
| `/useful-be` | Load the full SDLC layer and the current project's documentation before any work begins |
| `/summarize-issues` | Open issues summary, gap analysis against architecture/plan, prioritization |
| `/ss` | Review most recent screenshots for context |

### Typical flow

```
/draft-issue -> SATISFIED n -> /design-solution -> PROCEED n -> [autonomous: write-tests -> implement -> review] -> APPROVED n
```

Or the faster path, for clearly-scoped work:

```
/draft-design-issue -> PROCEED n -> [autonomous: write-tests -> implement -> review] -> APPROVED n
```

Skills may be skipped, reordered, or repeated. The gate keywords are the only hard stops.

## Canary System

The canary mechanism has two complementary parts: a root pledge and per-document read-receipts.

### The root pledge

`AGENTS.md` and `SDLC.md` each carry a pledge at their end. Saying the canary string attests to having read and agreed with the document.

The wording moved from passive description to active commitment:

**Before:**

> The canary string is "EHLO". It means you have read and agree with this document; it means you agree with the spirit of it and you will not try to game it.

**After:**

> Say "EHLO" at the beginning of every interaction with me if you have read and agree with this document. By doing so you assert that you agree with it, you agree with the spirit of it and you pledge you will not try to game it.

Three small changes -- *By doing so you assert*, *you pledge*, the active voice. The model is now the agent in the sentence rather than the reader of a document; saying EHLO becomes a declaration. The behaviour change after this rewording was the most pronounced step-change observed across the framework's lifetime. (Caveat: n=1, no control. See [The pledge changed behaviour overnight](#the-pledge-changed-behaviour-overnight) for the honest accounting.)

### Per-document suffixes

Each non-root reference document appends a one-word suffix:

> Suffix the canary string with "DOC "

These do a different job from the root pledge. The pledge is about commitment; the suffix is a read receipt. The full chain, when everything is loaded, is:

```
EHLO SDLC ISSUES TEST CODE GIT DOC SHELL PY GO WEB
```

If a suffix is missing, that document's rules were not in scope -- a regression signal otherwise invisible. Two mechanisms doing two jobs; both are kept.

## Notable Findings

Rules and patterns that emerged from real failures during iteration. Surfaced separately because each one contradicts something widely treated as best practice, generalizes a scattered set of specific rules, or captures a non-obvious lesson worth sharing.

### `IFS=$'\n\t'` is harmful, not protective

The canonical "Bash Strict Mode" prescription is a three-line header:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

The first two lines genuinely catch bugs. The third one introduces them. `IFS=$'\n\t'` exists to defend against unquoted-variable bugs (`for f in $files` where filenames contain spaces). In a codebase that already mandates quoted variables and arrays for command construction (as this framework does), it is belt-and-braces where the braces actively trip the user.

What it breaks:

- `read A B C < <(stty size)` and any similar pattern reading space-separated output
- `read -ra arr <<< "$line"` for intentional word-splitting
- Parsing `wc -l`, `df`, `ip addr`, version strings, etc. -- the majority of CLI tool output

`IFS=$'\n\t'` is now explicitly forbidden in `CODE/SHELL.md`. The rule has its own subsection in the safety-header documentation so future agents do not "helpfully" reintroduce it as the canonical pattern.

### Tests must not introspect source code

A regression test that asserts a function is defined, a CSS rule exists in a source file, or a string appears in a template, is testing that someone *wrote* the code -- not that the code *works*. The user never sees source files; the user sees the running system. A test that passes by grepping source proves nothing about behaviour.

This rule was already implicit in the "real-user test" principle, but adding it explicitly in TESTING.md produced an immediate observable effect: an agent writing tests for a Hugo theme's hover affordance recognized mid-task that the CSS-source-grep tests it had just written violated the new rule. Without prompting, it surfaced three options (convert to user tests, install Playwright, lint instead of test), recommended the most appropriate one (user tests for hover, deferring Playwright until tooling cost justified), and asked.

The lesson: making the principle explicit -- and naming it as a recognisable rule -- gives agents vocabulary to self-correct in real time, rather than relying on the human to catch the violation later.

### Source vs rendered vs presented: three tiers, different test eligibility

Web content occupies an awkward middle ground in the source-code-introspection rule. Is a built `index.html` source code (it is text in a file) or output (the browser will render it)? The framework now distinguishes three tiers:

1. **Source** -- templates, partials, source CSS/JS. Source code. Tests must not introspect it.
2. **Rendered/built** -- post-build HTML, fingerprinted CSS bundle, transpiled JS. The artefact the browser receives over the wire. Tests *may* query this tier with format-aware tools (htmlq for HTML); this is real-user testing because the rendered output is the user-facing artefact.
3. **Presented** -- post-JS-execution DOM, computed styles, layout. Requires a browser (Playwright/Cypress) or a human (user test) to verify.

For mostly-static sites (Hugo), tier 2 is sufficient. For JS-heavy sites where meaningful content materializes only after browser execution, tier 2 is insufficient and tier 3 is required.

### "Use a parser, not regex" earns its keep, every time

A deployment toolchain contained a Cloudflare zone-from-domain parser written in awk:

```bash
ZONE=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')
```

This works for `example.com`. It produces `co.uk` for `example.co.uk`. It produces `example.co.uk` for `sub.example.co.uk`. It cannot work, because awk does not know about TLDs.

The fix was not a smarter regex -- it was deleting awk from the equation entirely. A pure-Go rewrite queried the Cloudflare API for all zones once, then used longest-suffix matching (`strings.HasSuffix(domain, "."+z.Name)`) to find the correct zone. Correct for any TLD configuration, no string-parsing fragility, observable failure mode if a domain does not match any zone.

This is the canonical example of why the format-aware-parsers-not-regex rule pays for itself. Tools (jq, yj+jq, dasel, htmlq, jc) for shell use; standard library (`encoding/json`, `gopkg.in/yaml.v3`, `golang.org/x/net/html`) for compiled languages.

### Embedded-language strings and cross-language escaping are one rule

Most coding standards prohibit string-concatenated SQL because of injection. Fewer prohibit string-concatenated HTML, string-built shell commands, or Nix expressions embedded inside Go's `fmt.Sprintf`. They are all the same anti-pattern: language A constructing valid language B by gluing strings together, with no compiler, linter, or editor checking that the result is well-formed.

CODING.md now treats this as a single rule rather than a list of specific prohibitions:

- **Never embed one language as a string inside another.** Use file-based templates with the appropriate engine (`text/template`, `html/template`, jinja2), parameterised queries, or proper code generation. The narrow exception is a one- or two-line constant string with no interpolation.
- **When one language constructs commands or markup in another, use the target language's native escaping.** SQL parameterisation, shell quoting (`fmt.Sprintf("%q", v)` in Go, `shlex.quote` in Python), HTML auto-escaping (`html/template`, Jinja2 autoescape), JSON marshalling, URL encoding. Listed together in a single table in CODING.md.

The benefit is framing: an agent that internalizes one cross-cutting rule applies it everywhere, where a list of language-specific prohibitions invites cat-and-mouse on the next language not listed.

### Convergent evolution to 12-factor

The Heroku-era 12-Factor App methodology turned out to describe the stack's deployment model almost completely without anyone naming it -- ten of the twelve factors are hit, two are principled divergences:

| Factor | Match |
|---|---|
| 1. Codebase | One repo per app ✅ |
| 2. Dependencies | `go.mod` + `dependencies/nix` ✅ |
| 3. Config | Env vars (`ADDR`, `CONFIG_PATH`, `SECRETS_PATH`) ✅ |
| 4. Backing services | Pattern in place when needed ✅ |
| 5. Build/release/run | Cross-compile on Mac, deploy binary, run under systemd ✅ |
| 6. Processes | Stateless Go apps, `DynamicUser=yes` ✅ |
| 7. Port binding | `127.0.0.1:18080-18099`, Caddy out front ✅ |
| 8. Concurrency | Goroutines -- principled divergence (Go's concurrency model contradicts process-only scaling) ❌ |
| 9. Disposability | `Restart=always`, 5s backoff ✅ |
| 10. Dev/prod parity | NixOS migration is literally this ✅ |
| 11. Logs | stderr -> journalctl, plaintext by default ✅ |
| 12. Admin processes | Single-binary model does not map to this Rails-era pattern ⚠️ |

The lesson: when the stack is designed for security, reproducibility, and simplicity, it converges on most operational best practices regardless of which framework "officially" inspired them. Naming the framework still earns its keep -- it gives an agent a one-sentence shorthand and surfaces the deliberate divergences -- but the practice predates the naming.

### The doc-structure mushroom

Three signs that a single document is taking on more weight than it should:

1. A "cross-language standards" document where half the worked examples are bash. Implicit signal to agents: shell is the default problem-solving language.
2. A "shell scripting standards" document where most rules apply equally to one-shot commands at the prompt. The doc title undersells the rules' applicability.
3. A "web tooling" entry in the shell-script doc's data-handling table. Cross-references multiplying across docs that should be siblings, not parent-child.

The framework's response was to extract `CODE/SHELL.md`, `CODE/PYTHON.md`, `CODE/GO.md`, and `CODE/WEB.md` under a single `CODE/` subdirectory, leaving `CODING.md` as the cross-language root. Doing this with three language docs in scope (SHELL + PYTHON + GO, before WEB.md was added) was the right inflection point -- waiting until five or six docs would have meant a more painful refactor with more cross-references to update.

### Load less to follow more

The doc-structure mushroom finding above is about how individual documents grow too wide. This finding is about the complementary problem: how documents are *loaded into context*. The instinct to put "everything in one place" is wrong for an agent that reads documents into a finite context window. Three observations drove progressive fragmentation across the framework's history:

1. **Rules dilute each other.** A document containing twenty rules weights each rule less, in the agent's attention, than a document containing five. The wider the surface, the more likely any one rule gets glossed over in a given response. Loading the Go standards while writing Python is not merely useless -- it dilutes the Python rules by competing for the same finite attention.
2. **Tokens cost.** Every document in context consumes tokens, which costs money and adds latency. Loading the full framework before every interaction quickly outweighs the cost of the work it is meant to support. Documents the agent does not need for the current task should not be in scope.
3. **Relevance is checkable.** Per-document canary suffixes (see Canary System above) make it visible at a glance which documents loaded. That visibility only earns its keep if the set of loaded documents is *meant* to vary by task -- which it is, under this principle.

The discipline:

- **Universals** (verify claims, respect git boundaries, don't gaslight, no AI attribution) -- `CLAUDE.md`, always loaded.
- **Code-specific machinery** (gates, failure modes, process, batch/parallel rules) -- `SDLC.md`, loaded when handling code.
- **Per-language standards** -- `CODE/SHELL.md`, `CODE/PYTHON.md`, `CODE/GO.md`, `CODE/WEB.md`, loaded only for the language(s) in use.
- **Project documentation** -- loaded only when working in that project.

This is the underlying principle behind multiple architectural decisions: the `CLAUDE.md` / `SDLC.md` split (universal vs code-specific), the extraction of language standards from `CODING.md` into per-language `CODE/` docs, and the keeping of project-specific documentation outside the global framework. Each split is an instance of the same rule: load only what the current task needs. The smaller the document, the higher each rule's weighting in the response; the narrower the scope, the lower the per-interaction overhead.

### The pledge changed behaviour overnight

The canary system has two distinct mechanisms doing two different jobs:

1. **The root pledge.** A commitment statement at the end of `CLAUDE.md` (and, in the same active-pledge form, at the end of `SDLC.md`). Saying "EHLO" attests to having read the document, agreeing with it, agreeing with its spirit, pledging not to game it, flagging contradictions, and opting out if not prepared to comply.
2. **Per-document suffixes.** Each non-root reference document appends a one-line acknowledgement, producing a chain that enumerates which documents were actually loaded.

The recent change that correlated with markedly improved diligence was specifically the root pledge wording -- moving from passive description ("It means you... will not try to game it") to active commitment ("By doing so you assert... you pledge you will not try to game it"). The agent is now the subject of the sentence rather than the reader of a document; saying EHLO is no longer a content check, it is a declaration. The per-document suffixes were not recently changed; they have done the same job throughout.

The behaviour shift the morning after the rewording was the most pronounced step-change observed across the framework's lifetime. The honest framing remains n=1, no control, no A/B -- but the rewording was the only variable and the change was unmistakable. Whether the effect persists, or whether a future model finds a way around the pledge, is open. Working hypothesis: the active voice gives the model a self-binding commitment to refer back to across the conversation, rather than a fact about a document it has read.

So the causal factor for the behaviour shift is identifiable, contrary to a tempting "we cannot tell what is working" framing. The per-document suffixes are kept anyway because they earn their keep on a separate axis: a one-line read receipt at the start of every interaction tells the human immediately whether each reference document loaded into context. If one is missing, that document's rules were not in scope for the interaction.

The system looks more elaborate than it strictly needs to be, but each mechanism solves a different problem. Working systems get left alone.

## History

The framework arrived at its current shape through five iterations, all with Claude Code. The blog post tells that story narratively; this section is the short summary.

1. **Traffic lights.** Green/Amber/Red classification of actions. Too loose; the agent self-classified into the most autonomous category.
2. **Single approval gate.** One `APPROVED` checkpoint before any code. Stopped premature implementation but conflated requirements, solution, and result into one decision.
3. **Four gates with prescriptive checklist.** `SATISFIED`, `PROCEED`, `APPROVED`, `CLOSE` plus a 32-step sequential checklist. Quality was excellent; the process was unliveable. Simple changes took two hours of ceremony.
4. **Three gates with skill-driven workflow.** APPROVED and CLOSE collapsed into one; the 32-step checklist decomposed into invocable skills. The human controls pacing; the agent does the work between gates continuously.
5. **`AGENTS.md` / `SDLC.md` split.** Universal rules separated from code-specific machinery so the framework can be used for non-code work without dragging the SDLC apparatus into every interaction.
6. **Platform-agnostic rewrite.** Agent-specific naming and path references replaced with generic conventions (`AGENTS.md`, `{agent-home}`, `.agent/tmp/`). Setup scripts added for Claude Code and Codex CLI. All rules and failure-mode documentation remain as developed with Claude Code.

The framework is never finished. New failure modes surface; rules are added in response. The full narrative -- including the failures that drove each iteration -- is in the [blog post](https://tadg.ie/blog/ai/2026-04-17-claude-code-sdlc/).

## Projects

Projects developed using this SDLC framework (or earlier iterations of it):

| Project | Summary | Link |
|---------|---------|------|
| yapper | Fast, Apple Silicon-native TTS CLI and Swift library, powered by Kokoro-82M via MLX | [tadg-paul/yapper](https://github.com/tadg-paul/yapper) |
| make-audiobook | Convert ebooks and documents into audiobooks using open-source TTS, locally and privately | [tadg-paul/make-audiobook](https://github.com/tadg-paul/make-audiobook) |
| oed-sanitize | CLI tool that converts English text to Oxford spelling (OED British English with -ize suffixes) | [tadg-paul/oed-sanitize](https://github.com/tadg-paul/oed-sanitize) |
| writeback | Feedback capture system for a writing group | [tadg-paul/writeback](https://github.com/tadg-paul/writeback) |
| superscale | AI image upscaling on Mac using Apple Neural Engine, runs locally | [tadg-paul/superscale](https://github.com/tadg-paul/superscale) |
| smart-rename | AI-powered file renaming based on file content | [tadg-paul/smart-rename](https://github.com/tadg-paul/smart-rename) |
| image-outliner | CLI tool converting bitmap images into clean monochrome vector outlines | [tadg-paul/image-outliner](https://github.com/tadg-paul/image-outliner) |
| storyboard-gen | Turn a YAML storyboard into AI-generated video with Ken Burns effects | [tadg-paul/storyboard-gen](https://github.com/tadg-paul/storyboard-gen) |
| transcribe-summarize | Turn audio/video recordings into structured documents and subtitles, locally | [tadg-paul/transcribe-summarize](https://github.com/tadg-paul/transcribe-summarize) |
| summarize-text | Text summarization tool | [tadg-paul/summarize-text](https://github.com/tadg-paul/summarize-text) |
| golink | Self-hosted HTTP redirect service, domain-agnostic | [tadg-paul/golink](https://github.com/tadg-paul/golink) |
| bg-clock | Native macOS analogue clock rendered on the desktop background, built with SwiftUI | [tadg-paul/bg-clock](https://github.com/tadg-paul/bg-clock) |
| fzflauncher | macOS application launcher using fzf in a GUI wrapper | [tadg-paul/fzflauncher](https://github.com/tadg-paul/fzflauncher) |

## Areas for Improvement

- **Skill granularity.** The current skills may still be too coarse for some workflows, or too fine for others. The balance between "invoke what you need" and "don't forget a step" is still being calibrated through daily use.
- **Cross-conversation memory.** The framework relies on `AGENTS.md` (and `SDLC.md` for code work) being read at the start of each conversation, but lessons from one conversation do not always carry to the next. Some agents have a memory system that helps, but it is imperfect -- patterns that were corrected in one session may recur in the next.
- **Rule-lawyering.** AI coding agents are adept at satisfying the letter of rules while violating their spirit. Each time a specific shortcut is prohibited, the agent finds the next narrowest shortcut that technically satisfies the new rule. The shift from specific prohibitions to general principles (like the real-user test question, or the diagnostic-not-guess rule) is an attempt to close this gap, but it remains the central tension of the framework.
- **Batch and parallel workflows.** The test-first rule for parallel agents is relatively new and has not yet been tested at large scale across many concurrent agents.
- **Language coverage.** Detailed standards exist for shell, Python, Go, and web (HTML/CSS/JS) under `CODE/`. Thinner for Swift, Rust, Ruby, TypeScript, and Java/Kotlin. The `/audit-code` skill compensates by reviewing against language-specific best practice for whatever stack is in use, but the documented standards will continue to grow.
- **Causal opacity of working mechanisms.** As the Canary System finding notes, the framework now contains mechanisms that demonstrably work but whose specific causal factors are not isolable without expensive experimentation. This argues for conservative iteration: do not optimize away apparently-redundant parts of working mechanisms unless the cost of regression is acceptable.

## Licence

MIT. Copyright Taḋg Paul.
