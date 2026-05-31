# dotfiles

[![CI](https://github.com/AliSinaDevelo/dot-files/actions/workflows/ci.yml/badge.svg)](https://github.com/AliSinaDevelo/dot-files/actions/workflows/ci.yml)
[![Install test](https://github.com/AliSinaDevelo/dot-files/actions/workflows/install.yml/badge.svg)](https://github.com/AliSinaDevelo/dot-files/actions/workflows/install.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Cross-platform development environment for macOS and Windows. One command bootstraps a fresh machine into a fully configured setup.

## What's Included

### Shell & Terminal

| Config | Tool | Notes |
|--------|------|-------|
| `zsh/` | Zsh + Oh My Zsh + Powerlevel10k | macOS / WSL2 |
| `powershell/` | PowerShell 7 + Oh My Posh | Windows native |
| `tmux/` | Tmux | macOS / WSL2 — session persistence |
| `alacritty/` | Alacritty | Cross-platform terminal (Catppuccin Mocha) |
| `windows-terminal/` | Windows Terminal | Windows — tabs, multiple profiles |

### Editor

| Config | Tool | Notes |
|--------|------|-------|
| `nvim/` | Neovim + LazyVim | Cross-platform — LSP, Telescope, Treesitter, Catppuccin Mocha |

### Version Control

| Config | Tool | Notes |
|--------|------|-------|
| `git/` | Git + delta | Cross-platform — better diffs, aliases |

### CLI Tools

| Tool | Replaces | Purpose |
|------|----------|---------|
| `eza` | `ls` | File listing with icons and git status |
| `bat` | `cat` | Syntax-highlighted file viewer |
| `fd` | `find` | Fast file search |
| `ripgrep` | `grep` | Fast content search |
| `zoxide` | `cd` | Smart directory jumping |
| `fzf` | — | Fuzzy finder (shell history, files) |
| `delta` | — | Better git diffs |
| `lazygit` | — | Terminal git UI |
| `yazi` | — | Terminal file manager |
| `gh` | — | GitHub CLI |
| `jq` | — | JSON processor |
| `tldr` | `man` | Simplified command reference |

### AI Development Tools

| Tool | Purpose |
|------|---------|
| **Avante** (nvim) | Cursor-style AI coding assistant — Claude, GPT-4o, or local Ollama |
| **Copilot** (nvim) | GitHub Copilot inline ghost-text completions |
| `ollama` | Run LLMs locally (Llama, Mistral, Qwen, DeepSeek, CodeLlama) |
| `aider` | AI pair programming in the terminal — works with Claude & GPT |
| `llm` | Unified CLI for 100+ LLM providers |
| `gh copilot` | GitHub Copilot in the terminal (`gh copilot suggest "..."`) |

---

## Install

### macOS

**Prerequisites:** [Homebrew](https://brew.sh), Xcode Command Line Tools

```sh
git clone https://github.com/AliSinaDevelo/dot-files.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Linux

The same `install.sh` works on any Linux distro with [Homebrew for Linux](https://docs.brew.sh/Homebrew-on-Linux). GUI apps (Alacritty, fonts) are skipped automatically — install them via your distro's package manager.

```sh
# Install Homebrew for Linux first (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

git clone https://github.com/AliSinaDevelo/dot-files.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### macOS / Linux — after install

- Run `p10k configure` to style your prompt
- Open tmux and press `prefix + I` to install plugins
- Run `nvim` to let LazyVim auto-install plugins
- Set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in your shell for Avante AI

### Windows (native)

**Prerequisites:** PowerShell 7, Developer Mode enabled (`Settings → Privacy & Security → For Developers`)

```powershell
git clone https://github.com/AliSinaDevelo/dot-files.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

After install:
- Restart your terminal
- Run `nvim` to let LazyVim auto-install plugins
- In nvim, run `:MasonInstall <server>` for language servers

### Windows (WSL2)

After enabling WSL2 (`wsl --install`), open your Ubuntu shell and run the macOS install script — it works identically inside WSL:

```sh
cd /mnt/c/Users/<you>/dotfiles   # or wherever you cloned it
./install.sh
```

Both scripts are **idempotent** — safe to run again after pulling updates.

---

## Directory Structure

```
dotfiles/
├── alacritty/
│   └── alacritty.toml              # Terminal — Catppuccin Mocha (macOS + Windows)
├── git/
│   └── .gitconfig                  # Git aliases, delta pager, sensible defaults
├── nvim/                           # Neovim — LazyVim config (cross-platform)
│   ├── init.lua
│   └── lua/
│       ├── config/
│       │   ├── autocmds.lua        # Auto-commands (yank flash, whitespace, etc.)
│       │   ├── keymaps.lua         # Custom keybindings on top of LazyVim defaults
│       │   ├── lazy.lua            # lazy.nvim bootstrap + extras
│       │   └── options.lua         # Vim options
│       └── plugins/
│           ├── colorscheme.lua     # Catppuccin Mocha
│           ├── editor.lua          # Harpoon2
│           └── ai.lua              # Copilot + Avante (Claude / GPT / Ollama)
├── powershell/
│   └── profile.ps1                 # PowerShell — Oh My Posh, aliases, PSReadLine
├── tmux/
│   └── .tmux.conf                  # Tmux keybinds, status bar, TPM plugins
├── windows-terminal/
│   └── settings.json               # Windows Terminal — Catppuccin Mocha, Nerd Font
├── zsh/
│   └── .zshrc                      # Zsh — Oh My Zsh, plugins, aliases
├── Brewfile                        # macOS: Homebrew packages
├── install.sh                      # macOS / WSL2 bootstrap script
└── install.ps1                     # Windows bootstrap script
```

---

## Neovim (LazyVim)

The nvim config is built on [LazyVim](https://lazyvim.github.io) — an opinionated Neovim distribution with curated defaults and a plugin ecosystem.

### Included extras

| Extra | Purpose |
|-------|---------|
| **Telescope** | Fuzzy finder for files, grep, LSP symbols, buffers |
| **TypeScript LSP** | TypeScript / JavaScript language server |
| **JSON LSP** | JSON with schema support |
| **Markdown** | Preview, concealment, formatting |
| **Prettier** | Code formatter |
| **mini-animate** | Smooth cursor / scroll animations |

### Key bindings

`<Space>` is the leader key. Press it in Normal mode to see all keymaps via which-key.

| Key | Action |
|-----|--------|
| `<Space>ff` | Find files (Telescope) |
| `<Space>fg` | Live grep (Telescope) |
| `<Space>fb` | Find buffers |
| `<Space>fc` | Commands palette |
| `<Space>fm` | Marks |
| `<Space>e` | File explorer (neo-tree) |
| `<Space>gg` | LazyGit |
| `<Space>xx` | Diagnostics (Trouble) |
| `<Space>l` | Lazy plugin manager |
| `<Space>cm` | Mason LSP installer |
| `<Space>ha` | Add file to Harpoon |
| `<Space>hh` | Harpoon quick menu |
| `<Space>h1–4` | Jump to Harpoon file 1–4 |
| `<Space>aa` | AI: ask / chat (Avante) |
| `<Space>ae` | AI: edit selection (Avante) |
| `<Space>at` | AI: toggle sidebar (Avante) |
| `<M-l>` | Copilot: accept inline suggestion |
| `jk` | Exit insert mode |
| `<C-s>` | Save file |
| `<A-j> / <A-k>` | Move line / selection up or down |

---

## Shell Aliases

Available on both macOS (zsh) and Windows (PowerShell):

| Alias | Expands To |
|-------|-----------|
| `ls` | `eza --icons` |
| `ll` | `eza -lah --icons --git` |
| `la` | `eza -a --icons` |
| `lt` | `eza --tree --icons --level=2` |
| `cat` | `bat` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gco` | `git checkout` |
| `gd` | `git diff` |
| `glg` | `git log --oneline --graph --all` |

---

## Tmux (macOS / WSL2) — prefix: `Ctrl-b`

| Key | Action |
|-----|--------|
| `\|` | Split horizontally |
| `-` | Split vertically |
| `h/j/k/l` | Navigate panes (vim-style) |
| `H/J/K/L` | Resize panes |
| `r` | Reload config |

---

## Updating

```sh
# macOS / WSL2
cd ~/dotfiles && git pull && ./install.sh

# Windows PowerShell
cd $HOME\dotfiles; git pull; .\install.ps1
```

## License

MIT
