#!/usr/bin/env bash
# Set up Claude Code to use this framework.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TARGET="${HOME}/.claude"

managed_targets=(
    "$TARGET/CLAUDE.md"
    "$TARGET/SDLC.md"
    "$TARGET/docs"
    "$TARGET/commands"
    "$TARGET/.gitignore"
)

move_to_backup() {
    local target="$1"
    local backup="${target}.bak"
    local archived_backup

    if [[ -e "$backup" || -L "$backup" ]]; then
        archived_backup="${backup}.$(date +%Y%m%d%H%M%S)"
        printf 'Moving existing backup aside: %s -> %s\n' "$backup" "$archived_backup"
        mv "$backup" "$archived_backup"
    fi

    printf 'Moving existing path to backup: %s -> %s\n' "$target" "$backup"
    mv "$target" "$backup"
}

prepare_target() {
    local target="$1"

    if [[ -L "$target" ]]; then
        printf 'Removing existing symlink: %s\n' "$target"
        unlink "$target"
    elif [[ -e "$target" ]]; then
        move_to_backup "$target"
    fi
}

install_symlink() {
    local source="$1"
    local target="$2"

    prepare_target "$target"
    ln -s "$source" "$target"
}

install_copy() {
    local source="$1"
    local target="$2"

    prepare_target "$target"
    cp "$source" "$target"
}

mkdir -p "$TARGET"

existing_targets=()
for target in "${managed_targets[@]}"; do
    if [[ -e "$target" || -L "$target" ]]; then
        existing_targets+=("$target")
    fi
done

if ((${#existing_targets[@]} > 0)); then
    printf 'Warning: existing managed paths in %s will be replaced:\n' "$TARGET"
    printf '  %s\n' "${existing_targets[@]}"
    printf 'Real files/directories will be moved to .bak; symlinks will be removed.\n\n'
fi

install_symlink "$REPO/AGENTS.md" "$TARGET/CLAUDE.md"
install_symlink "$REPO/SDLC.md" "$TARGET/SDLC.md"
install_symlink "$REPO/docs" "$TARGET/docs"
install_symlink "$REPO/commands" "$TARGET/commands"
install_copy "$REPO/.gitignore" "$TARGET/.gitignore"

printf 'Managed paths in %s:\n' "$TARGET"
ls -la "$TARGET/CLAUDE.md" "$TARGET/SDLC.md" "$TARGET/docs" "$TARGET/commands" "$TARGET/.gitignore"

printf '\nNext step -- review and merge into %s/settings.json:\n  %s/settings.example.json\n' \
    "$TARGET" "$REPO"
printf '(Do not replace an existing settings.json wholesale.)\n'
