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

# Every invocation explicitly scopes AI config roots to its fixture. A real
# CODEX_HOME or CLAUDE_CONFIG_DIR inherited by this test must never receive links.
run_installer() {
  local fixture_home="$1" codex_home="$2" claude_home="$3"
  shift 3
  env HOME="$fixture_home" CODEX_HOME="$codex_home" CLAUDE_CONFIG_DIR="$claude_home" \
    /bin/bash "$ROOT/install.sh" "$@"
}

assert_empty_directory() {
  local path="$1"
  [ -z "$(find "$path" -mindepth 1 -print)" ] || {
    printf 'Preview mode changed %s.\n' "$path" >&2
    exit 1
  }
}

assert_absent() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    printf 'Expected absent path: %s\n' "$path" >&2
    exit 1
  fi
}

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

assert_claude_import() {
  local claude_home="$1" imported_path
  imported_path="$(awk '/^@[^[:space:]]+$/ { print substr($0, 2); exit }' "$claude_home/CLAUDE.md")"
  case "$imported_path" in
    '' | /*)
      printf 'Expected a relative instruction import in %s/CLAUDE.md.\n' "$claude_home" >&2
      exit 1
      ;;
  esac
  [ -f "$claude_home/$imported_path" ] || {
    printf 'Claude instruction import does not resolve: %s\n' "$imported_path" >&2
    exit 1
  }
  cmp -s "$ROOT/ai/AGENTS.md" "$claude_home/$imported_path" || {
    printf 'Claude instruction import does not load the shared instructions.\n' >&2
    exit 1
  }
}

assert_ai_links() {
  local codex_home="$1" claude_home="$2"
  assert_link "$codex_home/AGENTS.md" "$ROOT/ai/AGENTS.md"
  assert_link "$claude_home/AGENTS.md" "$ROOT/ai/AGENTS.md"
  assert_link "$claude_home/CLAUDE.md" "$ROOT/ai/CLAUDE.md"
  assert_claude_import "$claude_home"
}

inventory() {
  local path="$1"
  (cd "$path" && find . -print | LC_ALL=C sort)
}

backup_path() {
  local destination="$1"
  local -a matches
  matches=("$destination".backup.*)
  if [ "${#matches[@]}" -ne 1 ] \
    || { [ ! -e "${matches[0]}" ] && [ ! -L "${matches[0]}" ]; }; then
    printf 'Expected exactly one backup for %s.\n' "$destination" >&2
    exit 1
  fi
  printf '%s\n' "${matches[0]}"
}

fresh_home="$TEMP_ROOT/fresh"
mkdir -p "$fresh_home"
run_installer "$fresh_home" '' '' --links-only >"$TEMP_ROOT/preview.log" 2>&1
assert_empty_directory "$fresh_home"
for destination in "$fresh_home/.codex/AGENTS.md" "$fresh_home/.claude/AGENTS.md" "$fresh_home/.claude/CLAUDE.md"; do
  grep -Fq "$destination" "$TEMP_ROOT/preview.log" || {
    printf 'Preview omitted instruction destination: %s\n' "$destination" >&2
    exit 1
  }
done
set +e
run_installer "$fresh_home" '' '' --links-only --backup-existing >"$TEMP_ROOT/backup-preview.log" 2>&1
backup_preview_status=$?
set -e
[ "$backup_preview_status" -eq 2 ] || {
  printf 'Backup without apply should exit 2, got %s.\n' "$backup_preview_status" >&2
  exit 1
}
assert_empty_directory "$fresh_home"

run_installer "$fresh_home" '' '' --apply --links-only >"$TEMP_ROOT/apply.log" 2>&1
assert_link "$fresh_home/.zshrc" "$ROOT/zsh/.zshrc"
assert_link "$fresh_home/.tmux.conf" "$ROOT/tmux/.tmux.conf"
assert_link "$fresh_home/.gitconfig" "$ROOT/git/.gitconfig"
assert_link "$fresh_home/.config/nvim" "$ROOT/nvim"
assert_link "$fresh_home/.config/alacritty/alacritty.toml" "$ROOT/alacritty/alacritty.toml"
[ -f "$fresh_home/.gitconfig.local" ]
assert_ai_links "$fresh_home/.codex" "$fresh_home/.claude"

# A second apply must preserve machine-local identity and avoid backup clutter.
printf '\n[user]\n  name = Fixture User\n' >>"$fresh_home/.gitconfig.local"
cp "$fresh_home/.gitconfig.local" "$TEMP_ROOT/git-local.expected"
inventory "$fresh_home" >"$TEMP_ROOT/before-repeat.txt"
run_installer "$fresh_home" '' '' --apply --links-only >"$TEMP_ROOT/repeat.log" 2>&1
inventory "$fresh_home" >"$TEMP_ROOT/after-repeat.txt"
cmp -s "$TEMP_ROOT/before-repeat.txt" "$TEMP_ROOT/after-repeat.txt"
cmp -s "$TEMP_ROOT/git-local.expected" "$fresh_home/.gitconfig.local"
assert_ai_links "$fresh_home/.codex" "$fresh_home/.claude"

# Overrides can live outside HOME and contain spaces. Preview must not create
# those roots, and apply must leave the default AI roots absent.
alternate_home="$TEMP_ROOT/alternate home"
alternate_codex="$TEMP_ROOT/alternate configs/Codex Space"
alternate_claude="$TEMP_ROOT/alternate configs/Claude Space"
mkdir -p "$alternate_home"
run_installer "$alternate_home" "$alternate_codex" "$alternate_claude" --links-only \
  >"$TEMP_ROOT/alternate-preview.log" 2>&1
assert_empty_directory "$alternate_home"
assert_absent "$TEMP_ROOT/alternate configs"
for destination in "$alternate_codex/AGENTS.md" "$alternate_claude/AGENTS.md" "$alternate_claude/CLAUDE.md"; do
  grep -Fq "$destination" "$TEMP_ROOT/alternate-preview.log" || {
    printf 'Preview omitted alternate instruction destination: %s\n' "$destination" >&2
    exit 1
  }
done
run_installer "$alternate_home" "$alternate_codex" "$alternate_claude" --apply --links-only \
  >"$TEMP_ROOT/alternate-apply.log" 2>&1
assert_ai_links "$alternate_codex" "$alternate_claude"
assert_absent "$alternate_home/.codex"
assert_absent "$alternate_home/.claude"
inventory "$TEMP_ROOT/alternate configs" >"$TEMP_ROOT/alternate-before-repeat.txt"
run_installer "$alternate_home" "$alternate_codex" "$alternate_claude" --apply --links-only \
  >"$TEMP_ROOT/alternate-repeat.log" 2>&1
inventory "$TEMP_ROOT/alternate configs" >"$TEMP_ROOT/alternate-after-repeat.txt"
cmp -s "$TEMP_ROOT/alternate-before-repeat.txt" "$TEMP_ROOT/alternate-after-repeat.txt"
assert_ai_links "$alternate_codex" "$alternate_claude"

# Setting one override must not change the other tool's default config root.
codex_only_home="$TEMP_ROOT/Codex override home"
codex_only_root="$TEMP_ROOT/Codex only config"
mkdir -p "$codex_only_home"
run_installer "$codex_only_home" "$codex_only_root" '' --apply --links-only \
  >"$TEMP_ROOT/codex-only.log" 2>&1
assert_ai_links "$codex_only_root" "$codex_only_home/.claude"
assert_absent "$codex_only_home/.codex"
claude_only_home="$TEMP_ROOT/Claude override home"
claude_only_root="$TEMP_ROOT/Claude only config"
mkdir -p "$claude_only_home"
run_installer "$claude_only_home" '' "$claude_only_root" --apply --links-only \
  >"$TEMP_ROOT/claude-only.log" 2>&1
assert_ai_links "$claude_only_home/.codex" "$claude_only_root"
assert_absent "$claude_only_home/.claude"

conflict_home="$TEMP_ROOT/conflict"
mkdir -p "$conflict_home/.config/nvim" "$conflict_home/.codex" "$conflict_home/.claude"
printf 'keep me\n' >"$conflict_home/.zshrc"
printf 'keep me too\n' >"$conflict_home/.config/nvim/marker"
printf 'keep Codex instructions\n' >"$conflict_home/.codex/AGENTS.md"
ln -s '../user-owned-missing.md' "$conflict_home/.claude/AGENTS.md"
printf 'keep Claude instructions\n' >"$conflict_home/.claude/CLAUDE.md"
inventory "$conflict_home" >"$TEMP_ROOT/conflict-before-preview.txt"
run_installer "$conflict_home" '' '' --links-only >"$TEMP_ROOT/conflict-preview.log" 2>&1
inventory "$conflict_home" >"$TEMP_ROOT/conflict-after-preview.txt"
cmp -s "$TEMP_ROOT/conflict-before-preview.txt" "$TEMP_ROOT/conflict-after-preview.txt"
set +e
run_installer "$conflict_home" '' '' --apply --links-only >"$TEMP_ROOT/conflict.log" 2>&1
conflict_status=$?
set -e
[ "$conflict_status" -eq 2 ] || {
  printf 'Conflict install should exit 2, got %s.\n' "$conflict_status" >&2
  exit 1
}
[ "$(cat "$conflict_home/.zshrc")" = 'keep me' ]
[ "$(cat "$conflict_home/.config/nvim/marker")" = 'keep me too' ]
[ ! -L "$conflict_home/.config/nvim/nvim" ]
[ "$(cat "$conflict_home/.codex/AGENTS.md")" = 'keep Codex instructions' ]
assert_link "$conflict_home/.claude/AGENTS.md" '../user-owned-missing.md'
[ "$(cat "$conflict_home/.claude/CLAUDE.md")" = 'keep Claude instructions' ]
[ -z "$(find "$conflict_home" -name '*.backup.*' -print)" ]

backup_home="$TEMP_ROOT/backup"
mkdir -p "$backup_home/.config/nvim" "$backup_home/.codex" "$backup_home/.claude"
printf 'backup me\n' >"$backup_home/.zshrc"
printf 'backup directory\n' >"$backup_home/.config/nvim/marker"
printf 'backup Codex instructions\n' >"$backup_home/.codex/AGENTS.md"
ln -s '../user-owned-missing.md' "$backup_home/.claude/AGENTS.md"
printf 'backup Claude instructions\n' >"$backup_home/.claude/CLAUDE.md"
run_installer "$backup_home" '' '' --apply --links-only --backup-existing \
  >"$TEMP_ROOT/backup.log" 2>&1
assert_link "$backup_home/.zshrc" "$ROOT/zsh/.zshrc"
assert_link "$backup_home/.config/nvim" "$ROOT/nvim"
find "$backup_home" -maxdepth 1 -name '.zshrc.backup.*' -type f | grep -q .
find "$backup_home/.config" -maxdepth 1 -name 'nvim.backup.*' -type d | grep -q .
assert_ai_links "$backup_home/.codex" "$backup_home/.claude"
[ "$(cat "$(backup_path "$backup_home/.zshrc")")" = 'backup me' ]
[ "$(cat "$(backup_path "$backup_home/.config/nvim")/marker")" = 'backup directory' ]
[ "$(cat "$(backup_path "$backup_home/.codex/AGENTS.md")")" = 'backup Codex instructions' ]
assert_link "$(backup_path "$backup_home/.claude/AGENTS.md")" '../user-owned-missing.md'
[ "$(cat "$(backup_path "$backup_home/.claude/CLAUDE.md")")" = 'backup Claude instructions' ]
inventory "$backup_home" >"$TEMP_ROOT/backup-before-repeat.txt"
run_installer "$backup_home" '' '' --apply --links-only --backup-existing \
  >"$TEMP_ROOT/backup-repeat.log" 2>&1
inventory "$backup_home" >"$TEMP_ROOT/backup-after-repeat.txt"
cmp -s "$TEMP_ROOT/backup-before-repeat.txt" "$TEMP_ROOT/backup-after-repeat.txt"
assert_ai_links "$backup_home/.codex" "$backup_home/.claude"

printf 'Installer preview, apply, AI import, idempotence, alternate roots, conflict, and backup tests passed.\n'
