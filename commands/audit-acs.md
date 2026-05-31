---
description: Challenge acceptance criteria for coverage gaps, missing edge cases, and quality violations. Advisory only -- no code or file changes.
---

Review the acceptance criteria for the current issue. Do not write any code or modify any files.

1. **Summarize the functionality.** In plain language, describe what this issue delivers from the user's perspective. Post this summary in chat.

2. **Enumerate edge cases.** For each AC, list the edge cases, boundary conditions, error states, and unusual inputs that could falsify it. Be adversarial -- think about what could go wrong, not just what should go right.

3. **Identify missing ACs.** Are there user-facing behaviours, error conditions, or integration points implied by the problem statement that no AC addresses? List them.

4. **Check AC quality.** Run the AC self-audit from ISSUES.md:
   - Does each AC describe a system state, not a test action?
   - Does it contain any forbidden language?
   - Does it pass the litmus test?

5. **Summarize.** Write the full findings to `./.claude/tmp/audit-acs-<NNN>.md` (project-relative scratch): missing edge cases, missing ACs, quality violations, with specific recommended additions or rewrites for each. Render and open: `~/bin/pandhtml ./.claude/tmp/audit-acs-<NNN>.md` (produces `./.claude/tmp/audit-acs-<NNN>.html`), then `open ./.claude/tmp/audit-acs-<NNN>.html`. **In chat: one line stating the totals (missing ACs, edge case gaps, quality violations) and the HTML path.**

Do not proceed past this audit. Wait for my response.
