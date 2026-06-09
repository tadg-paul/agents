# GitHub Issue Standards

This document defines issue structure and AC quality standards. The process workflow - when to create issues, when to stop for approval, when to audit - is in SDLC.md §3.

---

## Voice and tone

Issues must be written impersonally, in the third person. Describe the system, the problem, and the solution -- not who did what or who will decide. Issues outlive conversations and must stand on their own.

**Wrong:**
- "I noticed that the login fails when..."
- "Tadg wants us to reject invalid tokens."
- "We should add a check here."
- "This is for Tadg to choose."

**Right:**
- "Login fails when..."
- "The API must reject invalid tokens."
- "A check is required here."
- "Two options are presented below; the trade-offs are documented for decision."

---

## Well-formed issue

A well-formed issue must contain:

- A clear problem statement or feature description
- A solution section (see rules below)
- If there are multiple options, list them all and make a recommendation
- A table of Acceptance Criteria (see below)

---

## Acceptance Criteria table

| Column | Purpose |
|---|---|
| **ID** | Format: `AC{issue}.{n}` - e.g. `AC12.1` |
| **AC** | A single, falsifiable *state of the system* - not a test, not a user action, not an implementation step. Write it as: *"Given [context], [system] [does/returns/stores/rejects] [X]."* If it describes something a test *does*, rewrite it as what the system *must be true of*. |
| **Tests** | Each test on its own line: `{status} {ID}: {description}`. Removed tests use strikethrough: `~~🚫 {ID}: {description}~~`. AC status is implicit - all ✅ = passing, any ❌ = failing, any ⏳ = pending. **Multiple tests per AC are expected and the norm.** |

Every AC table must end with a key line:

**Key:** ✅ passing · ⏳ pending · ❌ failing · ~~🚫 removed~~

### Single source of truth

Each AC has exactly one canonical home at any time.

- **While the issue is open:** the home is the issue body, or the first comment if GitHub's interface required the solution and ACs to be posted there. This covers drafting (pre-SATISFIED), solution design, implementation, review, and AWAITING APPROVAL.
- **At closure (after APPROVED):** the home becomes `./docs/ACs.md` (see §"Central AC document"). AC migration is part of the close ceremony -- the ACs move out of the (now-closed) issue and into the central spec as their permanent home.
- The central document is not a "second AC table" - it is the AC's permanent home post-closure. The issue is the change that introduced the ACs; the spec is where they live afterwards.

Earlier iterations migrated ACs at SATISFIED. That was reverted because the combined `/draft-design-issue` path collapses SATISFIED into PROCEED, leaving no natural moment for the human to review the central-doc state before authorization. Close-time migration makes the migration automatic, atomic with closure, and impossible to forget.

Rules that hold across both locations:

- The issue AC table column definitions, Tests-entry format, status emoji, removed-entry strikethrough format, and key line apply equally after migration to `./docs/ACs.md`.
- Never create a second AC table in a later comment, even if ACs have changed.
- If ACs need to change, edit them in place (in the issue during drafting, in `./docs/ACs.md` after migration). Add a comment on the originating issue summarizing what changed and why.
- Duplicating ACs across locations is a known failure mode: it creates ambiguity about which are current.

### AC quality heuristic

A well-defined AC describes a single, falsifiable system state - and nearly always requires more than one test to verify. An AC with exactly one test is a smell: either the AC is too narrow (and is really a test in disguise), or the test coverage is incomplete.

Before accepting single-test coverage for any AC, ask: *"What other inputs, edge cases, or boundary conditions could falsify this?"* If the answer is none, the AC may need rewriting. If the answer is several, the tests are missing.

### Multi-condition ACs require multi-condition coverage

If an AC implies multiple distinct conditions, it requires a test for each condition. An AC like *"The API rejects requests with invalid, expired, or missing tokens"* implies three conditions: invalid, expired, and missing. Each condition requires its own test. Writing a single test for one of the three conditions and marking the AC as passing is a process violation.

Before writing tests, enumerate the conditions each AC implies. Post this enumeration as a comment on the issue. Every condition must map to at least one test.

---

## The AC/Test boundary

> An **AC** describes *what must be true about the system*.
> A **Test** describes *how you confirm it is true*.

### The litmus test

Ask: *"Could this statement be true or false without specifying how it is observed?"* If not - if it describes an action someone performs to check something - it is a test, not an AC.

### Forbidden language in the AC column

The following words and phrasings are **strictly forbidden** in the AC column. If any AC contains them, rewrite it before proceeding.

**Action verbs:** call, assert, send, check, verify, run, execute, invoke, trigger, submit, click, request, query, fetch, post

**Passive test phrasings:** "is returned", "results in", "produces", "yields", "should return", "should produce", "responds with", "outputs"

**Test-structure language:** "when you", "if you", "given that we send", "after calling"

### Examples

| ❌ Wrong (test description) | ✅ Right (system state) |
|---|---|
| Call the API with an invalid token and assert a 401 is returned. | The API rejects requests with invalid tokens with HTTP 401. |
| Send a POST to /users with a duplicate email and check that a 409 is returned. | The system prevents duplicate user registration. |
| Run the export command with an empty dataset and verify the output file is empty. | Exporting an empty dataset produces an empty file. |
| Check that the config file is created in ~/.config/app/ after installation. | Installation creates a configuration file at ~/.config/app/. |
| Call the validate function with a malformed date string and assert it raises ValueError. | The validator rejects malformed date strings. |
| Verify that when the --verbose flag is passed, debug output is printed to stderr. | The --verbose flag enables debug output on stderr. |

### Self-audit procedure

After drafting ACs, perform this audit on every row of the AC table:

1. Read the AC column aloud. Does it describe an action someone performs, or a state the system is in?
2. Does it contain any word from the forbidden list above?
3. Apply the litmus test: could this be true or false without specifying how to observe it?

If any AC fails any of these checks, rewrite it before creating or updating the issue.

---

## Solution section rules

- If no solution is documented yet, add a new comment with the solution
- Do not litter the issue with multiple superseded solutions
- If a solution already exists, edit it in place to reflect the updated approach
- Add a comment summarizing what changed and why

---

## Sub-issues

Sub-issues may be created as needed to break down complex work. They are appropriate where:
- A discrete piece of work can be tracked and tested independently
- The scope is large enough to warrant it (e.g. a major refactor, a code review)

Every sub-issue must also conform to this standard - a well-formed issue with AC table, solution outline, and test IDs. Sub-issues are not lightweight stubs.

---

## AC and test ID allocation

- ACs follow the pattern `AC{issue}.{n}` - e.g. the first AC in issue #12 is `AC12.1`, then `AC12.2`, and so on.
- Test IDs follow the same issue-scoped pattern: `RT-{issue}.{n}`, `OT-{issue}.{n}`, `UT-{issue}.{n}` - e.g. the first regression test for issue #12 is `RT-12.1`, the second is `RT-12.2`. Each prefix has its own sequence within the issue.
- IDs become immutable **once the issue has passed Gate 1 (SATISFIED)**. After sign-off, never renumber, reuse, or delete IDs. If an AC is removed post-sign-off, mark it as `🚫 removed` in the table but do not delete the row or its ID. If a test is removed post-sign-off, mark it as removed in the test suite but do not delete the test or its ID.
- **Before** Gate 1, ACs and tests are draft text. They may be freely added, edited, removed, or renumbered without strikethrough or removal markers - drafting is iterative until SATISFIED.

---

## Central AC document

For projects of non-trivial size, ACs live in `./docs/ACs.md` - a single canonical spec that is grep-able, citeable, and reviewable as a whole. The originating issue is the historical record of the change; the central document is the spec of the resulting system.

### Structure

Group ACs by feature area, not by issue. AC IDs remain issue-scoped (do not renumber) - they just acquire a new home.

The central document preserves the issue AC table semantics. Each migrated AC entry carries the same AC text and the same Tests content: status emoji, test ID, type prefix, description, removed-test strikethrough where applicable, and the same key line used in issue AC tables.

```markdown
# Acceptance Criteria

This is the canonical spec. ACs introduced from YYYY-MM-DD onward live here.
Pre-cutover ACs remain in their originating issues until cited or migrated.

Last migrated: AC18.2 from #18 on YYYY-MM-DD

---

## <Feature area>

### AC{issue}.{n} - <falsifiable system state, copied verbatim>
- Introduced: #{issue} (closed YYYY-MM-DD)
- Tests:
  - ✅ RT-{issue}.1: <description>
  - ⏳ UT-{issue}.1: <description>
  - ~~🚫 OT-{issue}.1: <description>~~

**Key:** ✅ passing · ⏳ pending · ❌ failing · ~~🚫 removed~~
```

### Immutability and supersession

The immutability rule from §"AC and test ID allocation" extends to the central document. Once an AC is in `./docs/ACs.md`, it is read-only history. If a later issue supersedes an AC, mark the old one with strikethrough and `🚫 superseded by AC{n}.{m}`:

```markdown
### ~~AC8.3 - 🚫 Superseded by AC12.1~~
```

### Not every project needs it

Small projects (one feature, a handful of ACs, all visible at a glance) do not need a central AC document. The forcing function to introduce one is the cost of finding an AC: when you have to grep through closed issues to locate a spec, the central document earns its keep.

---

## Legacy AC migration

For existing projects with ACs scattered across closed issues, the migration to the central document is **on-demand, not big bang**. Bulk extraction imports stale ACs that no longer apply and bypasses the quality re-read.

### Migration policy

- **New issues (from cutover date):** follow the standard flow - ACs move to `./docs/ACs.md` at SATISFIED.
- **Legacy issues (pre-cutover, closed):** ACs remain in the issue body. They are citeable as `AC{n}.{m} (legacy - see #N)` until migrated.
- **Forcing function:** any work that references a legacy AC must either (a) cite it as legacy for a one-shot reference, or (b) migrate it first and cite normally. Migrate when the AC is load-bearing and likely to be referenced again.

### Citation order

When looking up an AC: check `./docs/ACs.md` first; fall back to the originating issue if not found.

### Cutover marker

`./docs/ACs.md` carries a header stating the cutover date and the last-migrated AC. This tells anyone (agent or human) which ACs are guaranteed to be discoverable centrally and which require fallback search.

### Preservation

Migration preserves history. Copy the AC verbatim, keep the original ID, add provenance lines (`Introduced: #N (closed YYYY-MM-DD)`, `Migrated: YYYY-MM-DD`). The originating issue body is **not** edited during migration - it remains the historical record.

### Tooling

Use the `/migrate-acs N` skill (SDLC.md §3) to perform the per-issue migration. It is user-invoked only - agents do not migrate ACs on their own initiative.

---

## Bug-fix issues reference existing ACs

When a bug violates an existing AC, the fix does not need a new AC. It needs a regression test that proves the original AC holds.

### Rule

A bug-fix issue must cite the AC(s) it violates by ID. The bug issue does not contain its own AC table; instead it points at `./docs/ACs.md` (or the legacy issue if not yet migrated).

### Two paths

1. **The bug violates an existing AC.** Cite the AC by ID. Add regression test(s) to the test suite for the original AC's coverage. Bug is closed when the test passes and the original AC is shown to hold.
2. **The bug has no covering AC.** Two sub-cases:
   - The underlying feature has an AC table but the bug exposes a gap. Backfill the AC on the original feature (edit `./docs/ACs.md` in place, with a comment on the originating issue noting the addition).
   - The underlying behaviour was never specified. Treat as a new feature - `/draft-issue` not `/draft-bug-fix` - and define the AC properly.

### What this prevents

Manufacturing parallel ACs for the same system state. If feature #12 has AC12.1 *"API rejects invalid tokens with 401"* and the bug is that it returns 500, the fix does not need a new AC like *"API does not return 500 for invalid tokens"* - that is the same state restated. Reference AC12.1 by ID; add a regression test under it.

### Use the right skill

- `/draft-bug-fix` for bug-fix issues. Mandatory first step: locate the violated AC(s). If none exists, prompt for backfill vs. new-feature decision.
- `/draft-issue` for new features (which create new ACs).

---

## Discovery issues

Discovery (sketching / exploratory UX work) is a first-class workflow, distinct from BYPASS-GATE-7 (which is for small clearly-scoped tasks). Discovery is for the opposite: open-ended work where the spec is not yet known.

### Properties

- A discovery issue has the title prefix `[DISCOVERY]` to keep it visually distinct from feature issues.
- It carries the `discovery` label (created if absent).
- It has **no AC table**. ACs presuppose a known spec; discovery is the work of finding one.
- Code may be written freely during discovery. Commits are marked `wip(discovery): ...` to make their provenance visible. They stay in master history regardless of outcome.

### Lifecycle

- `/start-discovery` opens (or re-uses) a discovery issue.
- During discovery, sketches accumulate. The issue is the running record of what was tried.
- `/end-discovery` exits in one of two ways, both non-destructive:
   - **Promote (default):** discovery iterations are real implementation. The discovery issue is the issue - no separate feature issue is drafted. Work is formalized into `./docs/ACs.md` with covering tests, then the issue is closed.
   - **Rule out:** the direction is a dead end. The `wip(discovery):` commits are reverted via `git revert`, then the issue is closed with a summary.

See `/end-discovery` for the mechanics. Both outcomes are valid - sometimes discovery's job is to rule things out.

### Not a long-term parking spot

Discovery issues should be short-lived (hours to days). A discovery issue that has been open for weeks is a signal to either promote, rule out, or split off a specific bounded question.

---

# Canary
Suffix the canary string with "ISSUES "
