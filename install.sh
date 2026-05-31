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

# ── Platform detection ────────────────────────────────────────────────────────
IS_MAC=false; IS_LINUX=false
case "$(uname -s)" in
  Darwin) IS_MAC=true ;;
  Linux)  IS_LINUX=true ;;
  *)      die "Unsupported OS: $(uname -s)" ;;
esac

# ── Homebrew ─────────────────────────────────────────────────────────────────
step "Homebrew packages"
if ! command -v brew &>/dev/null; then
  if $IS_MAC; then
    die "Homebrew not found. Install it first: https://brew.sh"
  else
    die "Homebrew not found. Install it first: https://docs.brew.sh/Homebrew-on-Linux"
  fi
fi
brew bundle --file="$DOTFILES/Brewfile" --no-lock
ok "Packages installed"

# ── Linux: fonts ─────────────────────────────────────────────────────────────
if $IS_LINUX; then
  step "Nerd Font (Linux)"
  FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
  mkdir -p "$FONT_DIR"
  BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
  declare -A FONTS=(
    ["MesloLGS-NF-Regular.ttf"]="MesloLGS%20NF%20Regular.ttf"
    ["MesloLGS-NF-Bold.ttf"]="MesloLGS%20NF%20Bold.ttf"
    ["MesloLGS-NF-Italic.ttf"]="MesloLGS%20NF%20Italic.ttf"
    ["MesloLGS-NF-BoldItalic.ttf"]="MesloLGS%20NF%20Bold%20Italic.ttf"
  )
  for dest in "${!FONTS[@]}"; do
    if [ ! -f "$FONT_DIR/$dest" ]; then
      curl -fLo "$FONT_DIR/$dest" "$BASE_URL/${FONTS[$dest]}"
      ok "Downloaded: $dest"
    else
      warn "Already exists: $dest"
    fi
  done
  fc-cache -fv >/dev/null 2>&1
  ok "Font cache updated"
fi

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

# ── GitHub Copilot CLI extension ──────────────────────────────────────────────
step "gh copilot extension"
if gh extension list 2>/dev/null | grep -q "gh-copilot"; then
  warn "Already installed"
elif gh auth status &>/dev/null; then
  gh extension install github/gh-copilot
  ok "Installed gh copilot"
else
  warn "Skipped (run 'gh auth login' first, then re-run this script)"
fi

# ── Symlinks ──────────────────────────────────────────────────────────────────
step "Config symlinks"
symlink "$DOTFILES/zsh/.zshrc"               "$HOME/.zshrc"
symlink "$DOTFILES/tmux/.tmux.conf"          "$HOME/.tmux.conf"
symlink "$DOTFILES/git/.gitconfig"           "$HOME/.gitconfig"
symlink "$DOTFILES/nvim"                     "$HOME/.config/nvim"

if $IS_MAC; then
  symlink "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
else
  # On Linux, Alacritty also uses ~/.config/alacritty
  symlink "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  warn "Alacritty must be installed separately on Linux (apt/dnf/cargo)"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}All done!${NC}"
echo "  • Restart your terminal or run: source ~/.zshrc"
echo "  • Run 'p10k configure' to set up your prompt"
echo "  • In tmux, press prefix + I to install plugins"
echo "  • Run 'nvim' to let LazyVim auto-install plugins"
echo "  • Set ANTHROPIC_API_KEY or OPENAI_API_KEY for Avante AI (in nvim)"
echo "  • Run 'ollama pull qwen2.5-coder' to download a local coding model"
