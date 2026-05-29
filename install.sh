#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

step()    { echo -e "\n${BOLD}${BLUE}==>${NC}${BOLD} $1${NC}"; }
ok()      { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}!${NC} $1"; }
die()     { echo -e "  ${RED}✗${NC} $1"; exit 1; }

symlink() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    warn "Already linked: $(basename "$dst")"
  else
    ln -sf "$src" "$dst"
    ok "Linked: $dst"
  fi
}

# ── Homebrew ─────────────────────────────────────────────────────────────────
step "Homebrew packages"
command -v brew &>/dev/null || die "Homebrew not found. Install it first: https://brew.sh"
brew bundle --file="$DOTFILES/Brewfile" --no-lock
ok "Packages installed"

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
step "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  warn "Already installed"
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Installed"
fi

# ── Powerlevel10k ─────────────────────────────────────────────────────────────
step "Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  warn "Already installed"
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  ok "Installed"
fi

# ── Tmux Plugin Manager ───────────────────────────────────────────────────────
step "Tmux Plugin Manager"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  warn "Already installed"
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "Installed"
fi

# ── Symlinks ──────────────────────────────────────────────────────────────────
step "Config symlinks"
symlink "$DOTFILES/zsh/.zshrc"               "$HOME/.zshrc"
symlink "$DOTFILES/tmux/.tmux.conf"          "$HOME/.tmux.conf"
symlink "$DOTFILES/git/.gitconfig"           "$HOME/.gitconfig"
symlink "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}All done!${NC}"
echo "  • Restart your terminal or run: source ~/.zshrc"
echo "  • Run 'p10k configure' to set up your prompt"
echo "  • In tmux, press prefix + I to install plugins"
