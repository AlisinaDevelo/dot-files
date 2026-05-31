# Shell
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# Terminal multiplexer
brew "tmux"

# Editor (requires >= 0.11.2 for LazyVim)
brew "neovim"

# Git
brew "git"
brew "delta"       # better diffs
brew "lazygit"     # terminal git UI
brew "gh"          # GitHub CLI

# Modern CLI replacements
brew "bat"         # cat with syntax highlighting
brew "eza"         # ls with icons + git status
brew "fd"          # faster find
brew "ripgrep"     # faster grep

# Navigation & search
brew "fzf"         # fuzzy finder
brew "zoxide"      # smart cd
brew "yazi"        # terminal file manager

# Data & HTTP
brew "jq"          # JSON processor
brew "curl"
brew "wget"

# DevOps / infra
brew "kubernetes-cli"
brew "kubectx"

# Utilities
brew "direnv"      # per-directory env vars
brew "tldr"        # simplified man pages
brew "sshs"        # SSH profile switcher

# AI development tools
brew "aider"       # AI pair programming in the terminal
brew "llm"         # unified CLI for OpenAI, Anthropic, Ollama, and more

# Skip large downloads in CI (ollama is ~2 GB)
unless ENV["CI"]
  brew "ollama"
end

# macOS-only: GUI apps and fonts (skipped automatically on Linux)
# Skipped in CI to keep install times reasonable
on_macos do
  unless ENV["CI"]
    cask "alacritty"
    cask "font-meslo-lg-nerd-font"
  end
end
