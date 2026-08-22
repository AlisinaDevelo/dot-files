#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY=false
LINKS_ONLY=false
BACKUP_EXISTING=false
LINK_CONFLICTS=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Preview is the default. No packages, downloads, or links are changed unless
--apply is supplied.

Options:
  --apply             apply the displayed plan
  --links-only        skip packages, fonts, and pinned shell dependencies
  --backup-existing   move conflicting destinations to timestamped backups
  -h, --help          show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply) APPLY=true ;;
    --links-only) LINKS_ONLY=true ;;
    --backup-existing) BACKUP_EXISTING=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if $BACKUP_EXISTING && ! $APPLY; then
  printf '%s\n' '--backup-existing requires --apply.' >&2
  exit 2
fi

if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
  NC=''
fi

step() { printf '\n%b==>%b%b %s%b\n' "$BOLD$BLUE" "$NC" "$BOLD" "$1" "$NC"; }
ok() { printf '  %bOK%b %s\n' "$GREEN" "$NC" "$1"; }
warn() { printf '  %bWARN%b %s\n' "$YELLOW" "$NC" "$1" >&2; }
die() {
  printf '  %bERROR%b %s\n' "$RED" "$NC" "$1" >&2
  exit 1
}

IS_MAC=false
IS_LINUX=false
case "$(uname -s)" in
  Darwin) IS_MAC=true ;;
  Linux) IS_LINUX=true ;;
  *) die "Unsupported OS: $(uname -s)" ;;
esac

LOCK_FILE="$DOTFILES/manifests/sources.lock"
[ -r "$LOCK_FILE" ] || die "Missing source lock: $LOCK_FILE"
# shellcheck source=manifests/sources.lock
. "$LOCK_FILE"

for required_var in \
  OH_MY_ZSH_REPO OH_MY_ZSH_REF \
  POWERLEVEL10K_REPO POWERLEVEL10K_REF \
  TPM_REPO TPM_REF \
  FONT_BASE_URL FONT_REGULAR_SHA256 FONT_BOLD_SHA256 \
  FONT_ITALIC_SHA256 FONT_BOLD_ITALIC_SHA256; do
  [ -n "${!required_var:-}" ] || die "Missing $required_var in $LOCK_FILE"
done

link_status() {
  local src="$1" dst="$2" target
  if [ -L "$dst" ]; then
    target="$(readlink "$dst")"
    if [ "$target" = "$src" ]; then
      printf 'linked'
    else
      printf 'conflict: symlink -> %s' "$target"
    fi
  elif [ -d "$dst" ]; then
    printf 'conflict: directory'
  elif [ -e "$dst" ]; then
    printf 'conflict: file'
  else
    printf 'new'
  fi
}

show_link() {
  local src="$1" dst="$2"
  printf '  %-42s %s\n' "$dst" "$(link_status "$src" "$dst")"
}

backup_destination() {
  local dst="$1" backup
  backup="${dst}.backup.$(date '+%Y%m%d%H%M%S')"
  if [ -e "$backup" ] || [ -L "$backup" ]; then
    backup="${backup}.$$"
  fi
  mv "$dst" "$backup"
  warn "Backed up $dst to $backup"
}

symlink_config() {
  local src="$1" dst="$2" target
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    target="$(readlink "$dst")"
    if [ "$target" = "$src" ]; then
      ok "Already linked: $dst"
      return
    fi
    if $BACKUP_EXISTING; then
      backup_destination "$dst"
    else
      warn "Skipped conflicting symlink: $dst -> $target"
      LINK_CONFLICTS=$((LINK_CONFLICTS + 1))
      return
    fi
  elif [ -e "$dst" ]; then
    if $BACKUP_EXISTING; then
      backup_destination "$dst"
    else
      warn "Skipped existing path: $dst"
      LINK_CONFLICTS=$((LINK_CONFLICTS + 1))
      return
    fi
  fi

  ln -s "$src" "$dst"
  ok "Linked: $dst"
}

cleanup_checkout() {
  local path="$1"
  case "$path" in
    *.dotfiles-install.*) rm -rf -- "$path" ;;
    *) warn "Refusing to clean unexpected temporary path: $path" ;;
  esac
}

normalize_repo() {
  local value="$1"
  case "$value" in
    git@github.com:*) value="https://github.com/${value#git@github.com:}" ;;
    ssh://git@github.com/*) value="https://github.com/${value#ssh://git@github.com/}" ;;
  esac
  printf '%s' "${value%.git}"
}

install_checkout() {
  local name="$1" repo="$2" ref="$3" dst="$4" origin head tmp

  if [ -d "$dst/.git" ]; then
    origin="$(git -C "$dst" remote get-url origin 2>/dev/null || true)"
    head="$(git -C "$dst" rev-parse HEAD 2>/dev/null || true)"
    if [ "$(normalize_repo "$origin")" != "$(normalize_repo "$repo")" ]; then
      warn "$name exists with a different origin; left untouched: $dst"
    elif [ "$head" != "$ref" ]; then
      warn "$name is installed at ${head:-unknown}, pinned ref is $ref; left untouched"
    else
      ok "$name is pinned at $ref"
    fi
    return
  fi

  if [ -e "$dst" ]; then
    warn "$name destination exists and is not a Git checkout; left untouched: $dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  tmp="${dst}.dotfiles-install.$$"
  if ! git init -q "$tmp" \
    || ! git -C "$tmp" remote add origin "$repo" \
    || ! git -C "$tmp" fetch -q --depth 1 origin "$ref" \
    || ! git -C "$tmp" checkout -q --detach FETCH_HEAD; then
    cleanup_checkout "$tmp"
    die "Failed to install $name"
  fi
  mv "$tmp" "$dst"
  ok "Installed $name at $ref"
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    die 'No SHA-256 utility found (need shasum or sha256sum)'
  fi
}

install_font() {
  local filename="$1" remote_name="$2" expected="$3" destination tmp actual
  destination="$FONT_DIR/$filename"
  if [ -f "$destination" ]; then
    actual="$(sha256_file "$destination")"
    if [ "$actual" = "$expected" ]; then
      ok "Font already verified: $filename"
    else
      warn "Existing font has a different checksum; left untouched: $destination"
    fi
    return
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-font.XXXXXX")"
  if ! curl -fsSL "$FONT_BASE_URL/$remote_name" -o "$tmp"; then
    rm -f -- "$tmp"
    die "Failed to download $filename"
  fi
  actual="$(sha256_file "$tmp")"
  if [ "$actual" != "$expected" ]; then
    rm -f -- "$tmp"
    die "Checksum mismatch for $filename"
  fi
  mv "$tmp" "$destination"
  ok "Installed verified font: $filename"
}

ensure_git_local() {
  local local_config="$HOME/.gitconfig.local"
  if [ -e "$local_config" ]; then
    ok "Machine-local Git config exists: $local_config"
    return
  fi

  printf '%s\n' \
    '# Machine-local Git identity and credential helpers.' \
    '# Configure with: git config --file ~/.gitconfig.local user.name "Your Name"' \
    '#                git config --file ~/.gitconfig.local user.email "you@example.com"' \
    >"$local_config"
  chmod 600 "$local_config"
  warn "Created $local_config; add your Git identity before committing"
}

step 'Plan'
printf '  Platform: %s (%s)\n' "$(uname -s)" "$(uname -m)"
printf '  Mode:     %s\n' "$($APPLY && printf 'apply' || printf 'preview')"
printf '  Packages: %s\n' "$($LINKS_ONLY && printf 'skip' || printf 'Homebrew plus pinned shell sources')"
printf '  Conflicts: %s\n' "$($BACKUP_EXISTING && printf 'backup then link' || printf 'preserve and report')"

step 'Config destinations'
show_link "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
show_link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
show_link "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
show_link "$DOTFILES/nvim" "$HOME/.config/nvim"
show_link "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

if ! $APPLY; then
  printf '\nPreview complete. Re-run with --apply after reviewing the plan.\n'
  exit 0
fi

if ! $LINKS_ONLY; then
  step 'Homebrew packages'
  command -v brew >/dev/null 2>&1 || die 'Homebrew is required; install it from https://brew.sh'
  brew bundle --no-upgrade --file="$DOTFILES/Brewfile"
  if $IS_MAC; then
    brew bundle --no-upgrade --file="$DOTFILES/Brewfile.macos"
  fi
  ok 'Homebrew manifests applied'

  step 'Pinned shell dependencies'
  install_checkout 'Oh My Zsh' "$OH_MY_ZSH_REPO" "$OH_MY_ZSH_REF" "$HOME/.oh-my-zsh"
  install_checkout \
    'Powerlevel10k' \
    "$POWERLEVEL10K_REPO" \
    "$POWERLEVEL10K_REF" \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  install_checkout 'Tmux Plugin Manager' "$TPM_REPO" "$TPM_REF" "$HOME/.tmux/plugins/tpm"

  if $IS_LINUX; then
    step 'Verified MesloLGS Nerd Fonts'
    FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
    mkdir -p "$FONT_DIR"
    install_font 'MesloLGSNerdFont-Regular.ttf' 'MesloLGSNerdFont-Regular.ttf' "$FONT_REGULAR_SHA256"
    install_font 'MesloLGSNerdFont-Bold.ttf' 'MesloLGSNerdFont-Bold.ttf' "$FONT_BOLD_SHA256"
    install_font 'MesloLGSNerdFont-Italic.ttf' 'MesloLGSNerdFont-Italic.ttf' "$FONT_ITALIC_SHA256"
    install_font 'MesloLGSNerdFont-BoldItalic.ttf' 'MesloLGSNerdFont-BoldItalic.ttf' "$FONT_BOLD_ITALIC_SHA256"
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f >/dev/null 2>&1
      ok 'Font cache updated'
    else
      warn 'fc-cache is unavailable; restart applications after installing fontconfig'
    fi
  fi
fi

step 'Config symlinks'
symlink_config "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
symlink_config "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
symlink_config "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
symlink_config "$DOTFILES/nvim" "$HOME/.config/nvim"
symlink_config "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
ensure_git_local

step 'Result'
if [ "$LINK_CONFLICTS" -gt 0 ]; then
  warn "$LINK_CONFLICTS destination(s) were preserved because they already exist"
  printf 'Review ./scripts/doctor.sh, then re-run with --apply --backup-existing when ready.\n'
  exit 2
fi

ok 'Dotfiles are installed'
printf '%s\n' \
  'Run ./scripts/doctor.sh to verify the active configuration.' \
  'Restart the terminal, run p10k configure, and open nvim to finish plugin setup.'
