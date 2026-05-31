#!/usr/bin/env bash
# Set up Claude Code to use this framework.
# Safe to re-run: -sf overwrites existing symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TARGET="${HOME}/.claude"

mkdir -p "$TARGET"

ln -sf "$REPO/AGENTS.md"  "$TARGET/CLAUDE.md"
ln -sf "$REPO/SDLC.md"    "$TARGET/SDLC.md"
ln -sf "$REPO/docs"       "$TARGET/docs"
ln -sf "$REPO/commands"   "$TARGET/commands"

printf 'Symlinks in %s:\n' "$TARGET"
ls -la "$TARGET/CLAUDE.md" "$TARGET/SDLC.md" "$TARGET/docs" "$TARGET/commands"

printf '\nNext step -- review and merge into %s/settings.json:\n  %s/settings.example.json\n' \
    "$TARGET" "$REPO"
printf '(Do not replace an existing settings.json wholesale.)\n'
