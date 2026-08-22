#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0
warnings=0

ok() { printf 'OK    %s\n' "$1"; }
warn() {
  printf 'WARN  %s\n' "$1"
  warnings=$((warnings + 1))
}
fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

check_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$command_name: $(command -v "$command_name")"
  else
    warn "$command_name is not installed"
  fi
}

check_link() {
  local source="$1" destination="$2" target
  if [ ! -L "$destination" ]; then
    if [ -e "$destination" ]; then
      fail "$destination exists but is not managed by this repository"
    else
      fail "$destination is missing"
    fi
    return
  fi
  target="$(readlink "$destination")"
  if [ "$target" = "$source" ]; then
    ok "$destination -> $target"
  else
    fail "$destination points to $target, expected $source"
  fi
}

normalize_repo() {
  local value="$1"
  case "$value" in
    git@github.com:*) value="https://github.com/${value#git@github.com:}" ;;
    ssh://git@github.com/*) value="https://github.com/${value#ssh://git@github.com/}" ;;
  esac
  printf '%s' "${value%.git}"
}

check_checkout() {
  local name="$1" repository="$2" revision="$3" path="$4" origin head
  if [ ! -d "$path/.git" ]; then
    warn "$name is not installed as a Git checkout: $path"
    return
  fi
  origin="$(git -C "$path" remote get-url origin 2>/dev/null || true)"
  head="$(git -C "$path" rev-parse HEAD 2>/dev/null || true)"
  if [ "$(normalize_repo "$origin")" != "$(normalize_repo "$repository")" ]; then
    warn "$name has an unexpected origin: ${origin:-missing}"
  elif [ "$head" != "$revision" ]; then
    warn "$name revision is ${head:-unknown}; pinned revision is $revision"
  else
    ok "$name is at its pinned revision"
  fi
}

printf 'Dotfiles doctor\n'
printf 'Platform: %s %s\n\n' "$(uname -s)" "$(uname -m)"

printf '[Repository]\n'
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "repository: $ROOT"
  origin="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  case "$origin" in
    *AlisinaDevelo/dot-files.git | *AliSinaDevelo/dot-files.git) ok "origin: $origin" ;;
    *) warn "unexpected origin: ${origin:-missing}" ;;
  esac
  hooks="$(git -C "$ROOT" config --get core.hooksPath 2>/dev/null || true)"
  if [ "$hooks" = '.githooks' ]; then
    ok 'local Git hooks enabled'
  else
    warn 'local Git hooks are not enabled; run ./scripts/setup-repo.sh'
  fi
else
  fail "$ROOT is not a Git worktree"
fi

printf '\n[Active links]\n'
check_link "$ROOT/zsh/.zshrc" "$HOME/.zshrc"
check_link "$ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"
check_link "$ROOT/git/.gitconfig" "$HOME/.gitconfig"
check_link "$ROOT/nvim" "$HOME/.config/nvim"
check_link "$ROOT/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
if [ -L "$HOME/.config/nvim/nvim" ]; then
  fail "$HOME/.config/nvim/nvim is a nested link left by an older installer"
fi

printf '\n[Pinned shell sources]\n'
# shellcheck source=manifests/sources.lock
. "$ROOT/manifests/sources.lock"
check_checkout 'Oh My Zsh' "$OH_MY_ZSH_REPO" "$OH_MY_ZSH_REF" "$HOME/.oh-my-zsh"
check_checkout \
  'Powerlevel10k' \
  "$POWERLEVEL10K_REPO" \
  "$POWERLEVEL10K_REF" \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
check_checkout 'Tmux Plugin Manager' "$TPM_REPO" "$TPM_REF" "$HOME/.tmux/plugins/tpm"

printf '\n[Identity and authentication]\n'
if git config --global --includes --get user.name >/dev/null 2>&1 \
  && git config --global --includes --get user.email >/dev/null 2>&1; then
  ok 'Git identity is configured through the machine-local include'
else
  fail 'Git identity is missing; configure ~/.gitconfig.local'
fi
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  ok 'GitHub CLI authentication is active'
else
  warn 'GitHub CLI authentication is unavailable'
fi
if command -v opencode >/dev/null 2>&1 && opencode acp --help >/dev/null 2>&1; then
  ok 'OpenCode ACP is available; direct cloud API keys are optional'
elif command -v kimi >/dev/null 2>&1; then
  ok 'Kimi CLI is available; direct cloud API keys are optional'
elif [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ]; then
  ok 'A direct cloud AI provider is configured'
else
  warn 'No ACP-capable AI CLI or direct cloud API key is available'
fi

printf '\n[Core commands]\n'
for command_name in git gh zsh tmux nvim alacritty rg fd fzf jq delta lazygit \
  opencode kimi ollama aider llm shellcheck shfmt stylua gitleaks; do
  check_command "$command_name"
done

printf '\nSummary: %s failure(s), %s warning(s)\n' "$failures" "$warnings"
[ "$failures" -eq 0 ]
