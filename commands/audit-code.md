---
description: Review implementation code against CODING.md and language best practice. Advisory only -- no file changes.
---

Review the implementation code for the current issue. Do not modify any files.

1. **Standards check.** Review all changed files against CODING.md and against best practice for the language(s) and stack(s) in use. CODING.md cannot enumerate patterns for every language -- apply community standards, idioms, and known pitfalls for this specific ecosystem alongside our own rules.

2. **Error handling.** Check every error path. Is each failure either a hard fail (let it crash) or properly handled with conditional logic? Flag any error suppression patterns (`|| true`, `|| rc=$?`, `set +e`, bare `except`, empty `catch`, etc.).

3. **Security.** Check for OWASP top 10 vulnerabilities, hardcoded credentials, injection risks, overly permissive permissions.

4. **Complexity.** Flag functions over 50 lines, nesting deeper than 3 levels, god objects, duplicated code.

5. **Summarize.** Write the full findings to `./.agent/tmp/audit-code-<NNN>.md` (project-relative scratch): each finding with file paths and line numbers, categorized as blockers (must fix) or smells (worth discussing), with a specific recommended fix for each. Render and open: `~/bin/pandhtml ./.agent/tmp/audit-code-<NNN>.md` (produces `./.agent/tmp/audit-code-<NNN>.html`), then `open ./.agent/tmp/audit-code-<NNN>.html`. **In chat: one line stating blocker count, smell count, and the HTML path.**

Do not proceed past this audit. Wait for my response.
