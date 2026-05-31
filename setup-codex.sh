#!/usr/bin/env bash
# Set up Codex CLI to use this framework.
# Safe to re-run: -sf overwrites existing symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TARGET="${HOME}/.codex"

mkdir -p "$TARGET"

ln -sf "$REPO/AGENTS.md"  "$TARGET/AGENTS.md"
ln -sf "$REPO/SDLC.md"    "$TARGET/SDLC.md"
ln -sf "$REPO/docs"       "$TARGET/docs"
ln -sf "$REPO/commands"   "$TARGET/prompts-commands"

printf 'Symlinks in %s:\n' "$TARGET"
ls -la "$TARGET/AGENTS.md" "$TARGET/SDLC.md" "$TARGET/docs" "$TARGET/prompts-commands"

printf '\nNext step -- review and merge into %s/config.toml:\n  %s/config.example.toml\n' \
    "$TARGET" "$REPO"
printf '(Do not replace an existing config.toml wholesale -- your [projects.*] trust entries will be lost.)\n'
