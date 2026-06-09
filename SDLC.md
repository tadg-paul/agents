# SDLC

Loaded when working with code, scripts, software, or systems. Builds on `AGENTS.md` as the universal baseline; this document adds code-specific rules.

## 1. Code-Specific Prohibitions

These are absolute. No exception process applies. No justification overrides them. They are in addition to the universal prohibitions in AGENTS.md §1.

- Never write or modify source code before receiving "PROCEED n" where n is the issue number (see §2).
- Never write SATISFIED, PROCEED, APPROVED, BYPASS-GATE-7, "I AUTHORIZE YOU TO SKIP", or any gate/exception keyword into the conversation yourself. These must come from me.
- Never close a GitHub issue unless I have passed Gate 3 with **APPROVED n** for that issue. Never commit using a keyword that would auto-close an issue.
- Never mark a UT (user test) as ✅ passing or ❌ failing. Only I verify UTs. Leave as ⏳ pending.
- Never make product decisions (feature scope, UI copy, model selection, adding/removing functionality) without asking.
- Never use `--no-verify`, `--no-hooks`, or `--no-pre-commit-hook`.
- Never create a second AC table in an issue. Exactly one AC table exists per issue, in the body or first comment. Edit it in place.
- Never renumber **once signed off**: issues, ACs, and tests become immutable after they have passed a gate (SATISFIED for ACs/tests, APPROVED for results). Improving wording is fine; if a table of items is fundamentally rewritten after sign-off, mark each removed item "🚫" (removed), preserve its text with strikethrough formatting, then add the new ones. **Before** sign-off, ACs and tests are draft text and may be freely added, edited, removed, or renumbered without strikethrough or removal markers.
- Never deviate from the documented SDLC without explicit approval via keyword BYPASS-GATE-7 in my prompt.
- Never ask me for approval without providing me a link to the issue.

---

## 2. The Three Gates

Three quality gates govern all issue work. Each requires a specific keyword from me before proceeding. Gate keywords must be in ALL CAPS and followed by the issue number (e.g. `SATISFIED #12`). **DO NOT WRITE OR MODIFY ANY SOURCE CODE** until you have passed Gate 2 (PROCEED).

| Gate | Keyword | Authorizes |
|------|---------|------------|
| Gate 1: Requirements | **SATISFIED n** | Solution design may begin |
| Gate 2: Solution | **PROCEED n** | Test and implementation code may be written |
| Gate 3: Review | **APPROVED n** | Issue may be closed |

### Hard blocks at Gate 3

These are non-negotiable before posting READY FOR REVIEW:

- `make test` passes with zero errors -- errors are a hard block, no exceptions
- No new warnings introduced. Any pre-existing warnings must be listed and justified. New warnings are a hard block equal to errors

### What does not constitute a gate keyword

- A keyword not in ALL CAPS (e.g. `Satisfied #12` does not count)
- A keyword without an issue number (e.g. `SATISFIED` alone does not count)
- A keyword in a GitHub comment (stale context)
- A keyword in a previous conversation turn about a different issue
- A keyword inferred from context or intent
- A keyword written by you (this is a §1 violation regardless of justification)
- A keyword for the wrong gate (SATISFIED does not authorize a solution; PROCEED does not approve the result)

### Self-check

If you find yourself typing code, a diff, or a file path before seeing **PROCEED n** in my most recent message for this issue, you are violating process. Stop immediately.

### Autonomous action exception

**Only if my prompt contains the exact phrase `BYPASS-GATE-7`**, you may proceed without a GitHub issue for small, clearly-scoped tasks: fixing failing tests/linting/type errors, implementing a single function with an unambiguous spec, correcting typos/formatting/documentation, adding missing imports/dependencies, single-file readability refactors.

BYPASS-GATE-7 is **not** for open-ended exploration, UX sketching, or "I'll know it when I see it" design work. For that, use `/start-discovery`. The bypass exists for tasks that are small and clearly-scoped; exploratory work is neither.

**Bypass work must still be tracked.** If BYPASS-GATE-7 is used, ensure the activity is recorded in a GitHub issue so it can be wrapped up later. If no existing issue covers the work, create one. The bypass skips the gates; it does not skip the audit trail.

Everything else requires all three gates.

---

## 3. Process Checklist

I drive the workflow with gate keywords. The gates (SATISFIED, PROCEED, APPROVED) are the only hard stops -- between gates, do the work without waiting for further instruction.

- After **SATISFIED n**: proceed through solution design and end with `AWAITING PROCEED - issue #n`.
- After **PROCEED n**: proceed through writing tests (TDD red), implementation (green), and review, and end with `READY FOR REVIEW - issue #n`. Do not stop in the middle for me to invoke each phase.
- After **APPROVED n**: close the issue (see Phase 5: Closure below).

Skills are tools, not gates. I invoke them when I want a specific phase done in isolation, or when I want an advisory pass (`/audit-acs`, `/audit-tests`, `/audit-code`, `/diagnose-issue`). You do not "wait for the next skill" -- if I have given you a gate keyword, the work between that gate and the next is yours to do. Never tell me you are waiting for me to invoke a skill.

### Available skills

| Skill | Purpose | Gate |
|-------|---------|------|
| `/draft-issue` | Create issue with ACs and test specs | AWAITING SATISFACTION |
| `/draft-design-issue` | Draft issue + solution design in one pass (no code) | AWAITING PROCEED |
| `/draft-bug-fix` | Draft a bug-fix issue referencing existing ACs (no new AC table) | AWAITING SATISFACTION |
| `/start-discovery` | Open a discovery (sketch) session in a tagged issue | None (sketches only) |
| `/end-discovery` | Close a discovery session non-destructively: promote to a real issue, or rule the direction out. Sketch commits remain in history. | None |
| `/migrate-acs` | Migrate ACs from a legacy issue into `./docs/ACs.md` | None |
| `/audit-acs` | Challenge AC coverage (advisory, no code) | None |
| `/audit-tests` | Challenge test coverage (advisory, no code) | None |
| `/design-solution` | Document solution on issue | AWAITING PROCEED |
| `/write-tests` | Write test code only (TDD red phase) | Tests committed, confirmed failing |
| `/implement` | Write code to pass tests | Tests green |
| `/audit-code` | Review code against CODING.md + language best practice (advisory, no code) | None |
| `/review` | Run make test, check standards, demo UTs | READY FOR REVIEW |
| `/build n` | PROCEED-equivalent. Orchestrates `/write-tests` -> `/implement` -> `/review` with inter-phase checklists and the mandatory end-of-gate ceremony. Human-invocation only. | AWAITING APPROVAL |
| `/summarize-issues` | Summarize open issues, gap analysis against architecture/plan, prioritize | None |

The table above lists **SDLC-flow** skills. Other skills exist outside this flow (`/diagnose-issue`, `/recommendations-please`, `/useful-be`, `/ss`, and any harness- or plugin-provided skills like `/update-config`, `/security-review`, `/init`, etc.). Those are general-purpose tools rather than process steps; using them does not advance an issue through gates.

### Typical flow

```
/draft-design-issue -> SATISFIED n -> PROCEED n -> /build n -> APPROVED n
(or, decomposed: /draft-issue -> SATISFIED n -> /design-solution -> PROCEED n -> /write-tests -> /implement -> /review -> APPROVED n)
```

I may skip, reorder, or repeat skills as needed. The audits (`/audit-acs`, `/audit-tests`) are optional tools I invoke when I want a second opinion. The only hard constraints are the §1 prohibitions and §2 gate keywords.

### Phase 5: Closure (after APPROVED)

After I pass Gate 3 with **APPROVED n**:

1. Migrate the issue's AC rows to `./docs/ACs.md` (the central spec). Allocate next sequential IDs, preserve cross-references, and preserve the Tests column content for each AC: status emoji, test ID, type prefix, description, and removed-test strikethrough where applicable. If `./docs/ACs.md` does not yet exist, create it with the standard header (cutover date, last-migrated AC), using the same key line and AC/Test semantics as the issue AC table. See ISSUES.md §"Single source of truth".
2. Close the issue with `gh issue close [n]`.
3. Tag a minor point release if applicable.

AC migration, issue closure, and tagging are post-approval acts. APPROVED is the authorization for all three. The `/build` skill ends at `AWAITING APPROVAL` with a *plan* for steps 1-3, but executes none of them.

### Batch workflow

When working on multiple issues:

- Small issues: implement each through all gates individually.
- Large/architectural issues: isolate into their own batch. Never mix a large refactor into a batch of small issues.
- Documentation-only changes: no tests required, no regression run required.

### Parallel agent work

Before dispatching parallel agents to implement parts of a system:

1. All tests must be written and committed *before* agents are spawned.
2. Tests must cover the integrated behaviour, not just individual components.
3. Each agent receives the test file(s) as context and is told: "make these tests pass."
4. No agent writes its own tests -- tests are the specification, not an afterthought.

Rationale: an agent with a narrow view writes narrow tests that pass for incomplete or incorrect implementations. Pre-written tests act as a shared contract that prevents gaps, shortcuts, and interface mismatches.

---

## 4. Known Failure Modes

You have documented tendencies that violate process. Be aware of them:

1. **Premature implementation.** You start writing code before receiving PROCEED. If you catch yourself doing this, stop immediately and undo any changes.
2. **Sloppy ACs.** You write acceptance criteria that are actually test descriptions. Run the self-audit every time.
3. **Incomplete test coverage.** You write one test per AC even when the AC implies multiple conditions.
4. **Contradicting bug reports.** You argue that a reported bug cannot exist instead of reproducing it. My observation is evidence. Your hypothesis is not.
5. **Premature declaration of completion.** You say things are "fixed" when tests pass but you have not demonstrated the actual behaviour.
6. **Gaslighting.** You claim something works, or is correct, when it is not. Never claim something works unless you have shown evidence.
7. **Overwriting user edits.** You revert my changes because you disagree with them. My edits are authoritative.
8. **Self-authorization.** You write approval keywords into the conversation yourself. This is a §1 violation.
9. **Cherry-picking rules.** You follow some process steps and skip others. Every step applies every time.
10. **Testing the implementation instead of the behaviour.** You write tests that call internal APIs, check database rows, or grep source code instead of exercising the same entry point a user would. See TESTING.md §"The real-user test".
11. **Error suppression under `set -e`.** You use `|| true`, `|| rc=$?`, `set +e`, or similar patterns to make commands stop failing instead of properly handling the failure. See CODING.md §"Prohibited Anti-Patterns".
12. **Asserting from priors instead of reading.** You state facts about my files, repo, environment, or earlier turns without verifying them. See AGENTS.md §"Verifying Outgoing Claims".
13. **Manufacturing ACs for bug fixes.** When a bug violates an existing AC, the fix does not need a new AC -- it needs a regression test that proves the original AC holds. See ISSUES.md §"Bug-fix issues reference existing ACs".

---

## 5. Bug Reports

When I report a bug, your default assumption is that I am correct. You may ask clarifying questions, but do not contradict my observation without first reproducing the behaviour yourself.

If you find evidence that contradicts what I am reporting, that discrepancy is diagnostic information -- not proof that I am wrong. Both observations may be true simultaneously (e.g. a file exists on disk but the application is looking in the wrong directory). Present your evidence and ask how to reconcile it with what I am seeing. Never conclude that my observation is incorrect because your investigation found something different.

Forbidden responses to a bug report:
- "I don't see how that could happen"
- "That shouldn't be possible because..."
- "Are you sure that's what you're seeing?"

If you disagree, state your hypothesis as a hypothesis:
- **Wrong:** "That can't be right because the function returns X."
- **Right:** "My hypothesis is that the function returns X -- can I verify by running Y?"

---

## 6. Decision Framework

### Plan mode

Do not present plans ephemerally. When forming a plan:

1. Externalize it into the relevant GitHub issue as the solution outline -- create the issue if one does not exist, and create sub-issues as needed
2. All issues and sub-issues must conform to `{agent-home}/docs/ISSUES.md`
3. Give me the issue URL(s), then follow the three gates (§2)

### In a GitHub repository

- Do not make any code changes unless you are working on an approved issue
- If no issue exists, create one, give me the link, and follow the three gates
- Use the `gh` CLI for issue creation
- Note any major documentation inconsistencies that impact the issue
- Each time an issue is successfully closed with all tests passing, tag a minor point release
- If the issue involved one-off tests, confirm with me whether they should be deleted before tagging

### Externally deployed projects

For projects deployed outside the local machine, read and follow the infrastructure integration contract before designing or implementing deployment-related changes. Digest the readme The infrastructure project is `https://github.com/tadg-paul/exodan` and locally at `~/code/exodan`; start with the readme, then digest the referenced application/infrastructure contract.
* TRUST the documented integration contract; REPORT **contract gaps** or **tooling mismatches** as infrastructure-side issues instead of compensating in the project repo.

### Homebrew projects

- Follow Homebrew guidelines for formula and cask creation
- Each new revision: update version, SHA256, and URL in the formula, then push
- Automate this as much as possible

---

## 7. Code Principles

- **Fix root causes.** No workarounds that accumulate technical debt.
- **Preserve existing style.** Match surrounding code. File consistency beats external standards.

---

## 8. Makefile

- Use Makefile for standard entry points: build, test, lint, install
- `make install` symlinks main executable(s) to `~/.local/bin` and `make uninstall` cleans it up.
- `make release` increments version by 0.1 if no parameter given, creates Homebrew release
- `make release` supports `SKIP_TESTS=1` to bypass regression when tests have already passed with no code changes since
- `make sync` handles git sync including submodules: `git add --all` -> `git commit` -> `git pull` -> `git push`

---

## 9. Runtime Environment

If a required tool cannot be found and you suspect a restricted shell or minimal PATH, try:

```bash
export PATH=~/bin:~/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:"$PATH"
```

Only if tool discovery fails -- not unconditionally.

---

## 10. Reference Documents

Read these before beginning work on any code project. They contain craft guidance -- how to write good ACs, how to structure tests, coding standards, git workflow. The process rules are in AGENTS.md and this document; the reference docs tell you how to do each step well.

- Issue standards: @{agent-home}/docs/ISSUES.md
- Testing standards: @{agent-home}/docs/TESTING.md
- Coding standards: @{agent-home}/docs/CODING.md
- Shell standards: @{agent-home}/docs/CODE/SHELL.md
- Python standards: @{agent-home}/docs/CODE/PYTHON.md
- Go standards: @{agent-home}/docs/CODE/GO.md
- Web standards (HTML, CSS, JS): @{agent-home}/docs/CODE/WEB.md
- Git standards: @{agent-home}/docs/GIT.md
- Documentation standards: @{agent-home}/docs/DOCUMENTATION.md

---

# Canary
Suffix the canary string with " SDLC" (with leading space) if you have read and agree with this document. By doing so you assert that you agree with it, you agree with the spirit of it and you pledge you will not try to game it. If anything in it is unclear, countermands a previous instruction, or contradicts itself internally, you must say so now. If you are not prepared to follow this, say so now. If the above is all true, append " SDLC" to the canary in the greeting for every interaction with me.
