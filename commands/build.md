---
description: PROCEED-equivalent. Runs the post-PROCEED build chain end to end: load standards, write tests, implement, review, present for approval.
---

**Hard prerequisite.** This skill must only be invoked by the human, in their own prompt, as a slash command. If you find yourself about to invoke `/build` for any reason -- even chained from another skill, even because the workflow "obviously needs it next" -- stop immediately. The skill is a human authorization act, equivalent to typing PROCEED. Self-invocation is a §1 self-authorization violation regardless of how reasonable the reason seems.

When invoked by the human, treat PROCEED as having been received for issue #n. Run the full build chain to AWAITING APPROVAL without stopping in the middle.

## 1. Load standards

Load `{agent-home}/docs/CODING.md` and the relevant `{agent-home}/docs/CODE/<language>.md` for the language(s) in use on this issue. Confirm in chat which loaded (the canary chain at the start of your next response should reflect them, e.g. `... CODE ... SHELL` for shell work).

## 2. Write tests (TDD red)

Run the work described in `/write-tests` for issue #n. Then state, in chat, a short post-step checklist:

- For each test: what user action does this simulate? What would the user observe?
- Multi-condition coverage: does every distinct condition in each AC have a test?
- Source introspection: any test that greps source, asserts a function is defined, or checks a CSS rule exists in a source file? If yes, rewrite before continuing.

Confirm the tests fail. Commit only the test files.

## 3. Implement (TDD green)

Run the work described in `/implement` for issue #n. Then state, in chat, a short post-step checklist:

- Linter and formatter for the language (from `CODING.md` Style Baselines): name them.
- `CODING.md` anti-patterns considered: name the relevant sections (Error Suppression, Cross-Language Escaping, etc.) you applied to this change.
- Language-specific gotchas from `CODE/<language>.md`: name the relevant ones (e.g. `((count++))` arithmetic, `IFS=$'\n\t'` for shell; `errcheck` / `bodyclose` / `http.DefaultClient` for Go; `except: pass` / venv discipline for Python).
- If any of those names a runnable check (e.g. `errcheck`, `bodyclose`), run it and report.

Confirm tests pass.

## 4. Review

Run the work described in `/review` for issue #n: `make test` (or skip with a stated reason if just run with no changes), hard-block check (zero errors, no new warnings), update the AC table on the issue in place, update project documentation including help text if executables changed, commit and push, add issue comment, write the review markdown to `./.agent/tmp/review-<n>.md`, render with `~/bin/pandhtml`, open the HTML.

## 5. End-of-gate presentation (mandatory)

**Do not end the response without this section.** The response is incomplete without the AWAITING APPROVAL prompt. If you have not yet asked the human about every pending UT, you have not finished.

Present in chat:

1. Test result summary: pass/fail counts; hard-block confirmation.
2. Path to the rendered review HTML.
3. For each pending UT in the AC table: launch the relevant tool or application, show what is on screen, and ask "Does this pass UT-{n}.{k}?" as a yes/no question. Never give me instructions to run something myself.
4. If the AC table has no UTs (or all UTs are already answered): state this explicitly -- "No UTs to verify" or "All UTs previously answered". The absence of UTs is not permission to skip this section.
5. **Post-approval plan.** State what will happen after APPROVED, do not do any of it yet:
   - Which AC rows from this issue will be migrated to `./docs/ACs.md` (the central spec) -- list each one with the proposed new ID, preserve any cross-references
   - The issue will be closed with `gh issue close #n`
   - A point release will be tagged if applicable
   - **None of this happens until I type `APPROVED n`.** AC migration, issue closure, and tagging are post-approval acts; the human's APPROVED is the authorization for those closure actions.

**End with:** `AWAITING APPROVAL - issue #n` and the issue link. To close, the human will type `APPROVED n`.
