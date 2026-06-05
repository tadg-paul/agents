#!/usr/bin/env bash
# Set up Claude Code to use this framework.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TARGET="${HOME}/.claude"

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

confirm_replace() {
    local target="$1"
    local reply

    printf 'Warning: %s exists and is not a symlink.\n' "$target"
    printf 'It will be moved to %s.bak before replacement.\n' "$target"
    if ! read -r -p 'Continue? (y/N) ' reply; then
        reply=
    fi

    case "$reply" in
        [Yy] | [Yy][Ee][Ss])
            return 0
            ;;
        *)
            printf 'Skipping %s\n' "$target"
            return 1
            ;;
    esac
}

same_path() {
    local source="$1"
    local target="$2"

    [[ -L "$target" && "$(readlink "$target")" == "$source" ]]
}

same_file() {
    local source="$1"
    local target="$2"

    [[ -f "$target" ]] && cmp -s "$source" "$target"
}

same_tree() {
    local source="$1"
    local target="$2"

    [[ -d "$target" ]] && diff -qr "$source" "$target" >/dev/null
}

prepare_target() {
    local source="$1"
    local target="$2"
    local kind="$3"

    if [[ "$kind" == symlink ]] && same_path "$source" "$target"; then
        printf 'Already current: %s\n' "$target"
        return 1
    fi

    if [[ ! -L "$target" && "$kind" == copy ]] && same_file "$source" "$target"; then
        printf 'Already current: %s\n' "$target"
        return 1
    fi

    if [[ ! -L "$target" && "$kind" == symlink && -f "$source" ]] && same_file "$source" "$target"; then
        printf 'Already current: %s\n' "$target"
        return 1
    fi

    if [[ ! -L "$target" && "$kind" == symlink && -d "$source" ]] && same_tree "$source" "$target"; then
        printf 'Already current: %s\n' "$target"
        return 1
    fi

    if [[ -L "$target" ]]; then
        printf 'Removing existing symlink: %s\n' "$target"
        unlink "$target"
    elif [[ -e "$target" ]]; then
        confirm_replace "$target" || return 1
        move_to_backup "$target"
    fi

    return 0
}

install_symlink() {
    local source="$1"
    local target="$2"

    prepare_target "$source" "$target" symlink || return 0
    ln -s "$source" "$target"
}

install_copy() {
    local source="$1"
    local target="$2"

    prepare_target "$source" "$target" copy || return 0
    cp "$source" "$target"
}

mkdir -p "$TARGET"

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
