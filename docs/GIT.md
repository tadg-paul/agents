# Git and Source Control

## Fundamental Rules

- **Never use `--no-verify`** when committing. Ever.
- Refuse to work on code not in a git repository.
- Before moving, changing, or removing files, ensure they're tracked and recoverable.

## Forbidden Flags

These are prohibited:
- `--no-verify`
- `--no-hooks`
- `--no-pre-commit-hook`
- NEVER state "Co-authoried by Claude" or any AI

Before using any unfamiliar git flag: state it, explain why, confirm it's not forbidden, get permission for any bypass.

## Commit Standards

Messages must be:
- Concise and descriptive
- Imperative mood, present tense
- Conventional commit format

```
feat: add user authentication
fix: resolve memory leak in data processor
docs: update API documentation
refactor: simplify validation logic
```

### Issue-linked commits

When a commit implements work tracked by a GitHub issue, use:

```
Implement #N: short description
```

**Never use GitHub auto-close keywords** (`Fixes`, `Closes`, `Resolves`, or their variants) in commit messages. Issues are closed manually after human review. Auto-closing bypasses that review step.

## Workflow

Before starting work:

```bash
git pull
git status
```

Ensure local repo is current with remote.

## Pre-Commit Hook Failures

When hooks fail, follow this sequence exactly:

1. Read complete error output (explain what you see)
2. Identify which tool failed and why
3. Explain the fix and why it addresses root cause
4. Apply fix, re-run hooks
5. Commit only after all hooks pass

Cannot fix? Ask for help. Never bypass.

## Project Hooks Must Chain to Global Hooks

When a project needs its own git hooks, the project hook must call the global hook first — never silently replace it. A project-local `.git/hooks/pre-commit` or a project-level `core.hooksPath` overrides the global hook entirely unless chaining is explicit.

Use this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Chain to global hook first — project hooks must not override global hooks
if global_hooks_path="$(git config --global core.hooksPath 2>/dev/null)"; then
    if [[ -x "$global_hooks_path/${0##*/}" ]]; then
        "$global_hooks_path/${0##*/}"
    fi
fi

# Project-specific checks below
```

Notes:
- `${0##*/}` resolves to the hook's own name (`pre-commit`, `pre-push`, etc.), so the pattern works for any hook type without modification.
- `set -e` ensures the global hook's exit code propagates — if the global hook fails, the project hook fails too.
- The `if` around `git config` handles the case where no global `core.hooksPath` is configured.

### Setup

Hooks in `.git/hooks/` are not version-controlled. To track project hooks in the repo:

1. Store hooks in a `hooks/` directory at the project root.
2. Copy them into `.git/hooks/` via a Makefile target:

```makefile
init:
	cp hooks/* .git/hooks/
```

This preserves the default hooks path, so any hook types the project doesn't define (e.g. `pre-push`, `commit-msg`) continue to work from the global configuration. Only the hooks the project explicitly provides are overridden — and the chaining pattern above ensures global hooks still run for those too.

## Pressure Response

When asked to commit/push with failing hooks:

- Do not rush to bypass quality checks
- State: "Pre-commit hooks are failing, I need to fix those first"
- Work through systematically
- Quality over speed, even when waiting

Pressure is never justification for bypassing checks.

## Accountability

Before any git command, ask:

- Am I bypassing a safety mechanism?
- Would this violate CLAUDE.md?
- Am I choosing convenience over quality?

If any answer is "yes" or "maybe", explain the concern first.

## Branch Strategy

Default: work on master.

If the issue specifies a feature branch:
- Create the branch
- Work only on that branch
- Push to origin

Alternatives available: worktrees, feature branches.

## Exception Process

When a rule genuinely cannot be followed (not "is inconvenient"):

1. **Document the situation** — what rule, why it can't be followed
2. **Get explicit approval** — from the project owner, in writing (issue comment, PR comment)
3. **Record the exception** — in the commit message or PR description
4. **Set an expiry** — exceptions should be temporary; create a follow-up issue to resolve properly

Format for commit messages with exceptions:
```
fix: emergency patch for production outage

EXCEPTION: Skipping integration tests - test DB unavailable
APPROVED BY: @owner in #123
FOLLOW-UP: #124 to restore test coverage
```

Exceptions are not get-out-of-jail-free cards. They create technical debt that must be repaid.

# Canary
Suffix the canary string with "GIT "
