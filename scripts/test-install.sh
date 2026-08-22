#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_BASE="${TMPDIR:-/tmp}"
TEMP_BASE="${TEMP_BASE%/}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/dotfiles-install-test.XXXXXX")"

cleanup() {
  case "$TEMP_ROOT" in
    "$TEMP_BASE"/dotfiles-install-test.*) rm -rf -- "$TEMP_ROOT" ;;
    *) printf 'Refusing to remove unexpected path: %s\n' "$TEMP_ROOT" >&2 ;;
  esac
}
trap cleanup EXIT HUP INT TERM

assert_link() {
  local path="$1" expected="$2"
  [ -L "$path" ] || {
    printf 'Expected symlink: %s\n' "$path" >&2
    exit 1
  }
  [ "$(readlink "$path")" = "$expected" ] || {
    printf 'Unexpected target for %s\n' "$path" >&2
    exit 1
  }
}

fresh_home="$TEMP_ROOT/fresh"
mkdir -p "$fresh_home"
HOME="$fresh_home" /bin/bash "$ROOT/install.sh" --links-only >/dev/null
[ ! -e "$fresh_home/.zshrc" ] || {
  printf 'Preview mode changed the fresh home.\n' >&2
  exit 1
}

HOME="$fresh_home" /bin/bash "$ROOT/install.sh" --apply --links-only >/dev/null
assert_link "$fresh_home/.zshrc" "$ROOT/zsh/.zshrc"
assert_link "$fresh_home/.tmux.conf" "$ROOT/tmux/.tmux.conf"
assert_link "$fresh_home/.gitconfig" "$ROOT/git/.gitconfig"
assert_link "$fresh_home/.config/nvim" "$ROOT/nvim"
assert_link "$fresh_home/.config/alacritty/alacritty.toml" "$ROOT/alacritty/alacritty.toml"
[ -f "$fresh_home/.gitconfig.local" ]

conflict_home="$TEMP_ROOT/conflict"
mkdir -p "$conflict_home/.config/nvim"
printf 'keep me\n' >"$conflict_home/.zshrc"
printf 'keep me too\n' >"$conflict_home/.config/nvim/marker"
set +e
HOME="$conflict_home" /bin/bash "$ROOT/install.sh" --apply --links-only >/dev/null 2>&1
conflict_status=$?
set -e
[ "$conflict_status" -eq 2 ] || {
  printf 'Conflict install should exit 2, got %s.\n' "$conflict_status" >&2
  exit 1
}
[ "$(cat "$conflict_home/.zshrc")" = 'keep me' ]
[ "$(cat "$conflict_home/.config/nvim/marker")" = 'keep me too' ]
[ ! -L "$conflict_home/.config/nvim/nvim" ]

backup_home="$TEMP_ROOT/backup"
mkdir -p "$backup_home/.config/nvim"
printf 'backup me\n' >"$backup_home/.zshrc"
printf 'backup directory\n' >"$backup_home/.config/nvim/marker"
HOME="$backup_home" /bin/bash "$ROOT/install.sh" --apply --links-only --backup-existing >/dev/null
assert_link "$backup_home/.zshrc" "$ROOT/zsh/.zshrc"
assert_link "$backup_home/.config/nvim" "$ROOT/nvim"
find "$backup_home" -maxdepth 1 -name '.zshrc.backup.*' -type f | grep -q .
find "$backup_home/.config" -maxdepth 1 -name 'nvim.backup.*' -type d | grep -q .

printf 'Installer preview, apply, conflict, and backup tests passed.\n'
