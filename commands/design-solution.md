---
description: Document the solution design for an existing issue. No code is written.
---

Document the solution design for the current issue. Do not write any code.

1. Fetch the issue with `gh issue view [n]` and read all comments -- there may have been changes since you last looked.
2. Verify the issue has exactly one AC table. If missing or duplicated, fix before proceeding.
3. Re-run the AC self-audit (see ISSUES.md §AC/Test boundary). If any AC violates the boundary, alert me and **STOP.**
4. Document the solution on the issue:
   - Language, frameworks, and libraries to use
   - Patterns to follow
   - Anti-patterns to avoid (cite specific CODING.md sections)
5. Review the solution against the codebase. If there are contradictions or the solution is unsound, alert me and **STOP.**
6. Allocate test file locations and test IDs.

**End with:** `AWAITING PROCEED - issue #NNN` and the issue link. **STOP.**
