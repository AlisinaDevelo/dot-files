#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required_commands='git bash zsh shellcheck shfmt luac stylua jq ruby brew markdownlint-cli2 taplo'
missing=''
for command_name in $required_commands; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing="$missing $command_name"
  fi
done
if [ -n "$missing" ]; then
  printf 'Missing validation commands:%s\nRun ./install.sh --apply or install them from Brewfile.\n' "$missing" >&2
  exit 1
fi

printf '==> Shell\n'
/bin/bash -n install.sh scripts/*.sh .githooks/*
shellcheck -x install.sh scripts/*.sh .githooks/*
shfmt -d -i 2 -ci -bn install.sh scripts/*.sh .githooks/*
zsh -n zsh/.zshrc

printf '==> Lua and Neovim\n'
find nvim -name '*.lua' -type f -exec luac -p {} \;
stylua --check nvim
[ -s nvim/lazy-lock.json ] || {
  printf 'nvim/lazy-lock.json must be tracked for reproducible plugins.\n' >&2
  exit 1
}

printf '==> Structured configuration\n'
while IFS= read -r json_file; do
  jq empty "$json_file"
done < <(find nvim windows-terminal -name '*.json' -type f -print)
taplo format --check alacritty/alacritty.toml .stylua.toml
ruby -c Brewfile >/dev/null
ruby -c Brewfile.macos >/dev/null
brew bundle list --file="$ROOT/Brewfile" >/dev/null
brew bundle list --file="$ROOT/Brewfile.macos" >/dev/null
git config --no-includes --file git/.gitconfig --list >/dev/null

printf '==> Application parsers\n'
if command -v alacritty >/dev/null 2>&1; then
  alacritty migrate --dry-run --skip-imports --config-file alacritty/alacritty.toml >/dev/null
else
  printf 'WARN: alacritty unavailable; skipped its native parser.\n' >&2
fi
if command -v tmux >/dev/null 2>&1; then
  socket_name="dotfiles-validate-$$"
  tmux -L "$socket_name" -f "$ROOT/tmux/.tmux.conf" new-session -d
  tmux -L "$socket_name" kill-server
else
  printf 'WARN: tmux unavailable; skipped its native parser.\n' >&2
fi
if command -v pwsh >/dev/null 2>&1; then
  # The single-quoted string is PowerShell code and must not expand in Bash.
  # shellcheck disable=SC2016
  pwsh -NoLogo -NoProfile -Command \
    '$failed = $false; foreach ($file in @("install.ps1", "powershell/profile.ps1")) { $tokens = $null; $errors = $null; [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors) > $null; if ($errors.Count) { $errors | Out-String | Write-Error; $failed = $true } }; if ($failed) { exit 1 }'
else
  printf 'WARN: pwsh unavailable; Windows scripts received static review only.\n' >&2
fi

printf '==> Documentation and portability\n'
markdownlint-cli2 '**/*.md' '#.git/**'
if rg -n '/Users/[A-Za-z0-9._-]+|C:\\Users\\[A-Za-z0-9._-]+' \
  install.sh install.ps1 zsh git nvim tmux alacritty powershell scripts; then
  printf 'Hard-coded home directory found in portable configuration.\n' >&2
  exit 1
fi
if rg -n 'github/gh-copilot|gh extension install' . \
  --glob '!.git/**' --glob '!nvim/lazy-lock.json' --glob '!scripts/validate.sh'; then
  printf 'Retired gh-copilot extension reference found.\n' >&2
  exit 1
fi

printf '==> Repository hygiene\n'
git diff --check
git diff --cached --check
./scripts/check-secrets.sh

printf 'All local validation checks passed.\n'
