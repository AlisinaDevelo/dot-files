# dotfiles

Personal macOS development environment. One command goes from a fresh machine to a fully configured setup.

## What's Included

| Config | Tool | Notes |
|--------|------|-------|
| `zsh/` | Zsh + Oh My Zsh + Powerlevel10k | Shell, prompt, aliases |
| `tmux/` | Tmux | Multiplexer with session persistence |
| `git/` | Git + delta | Version control with better diffs |
| `alacritty/` | Alacritty | GPU-accelerated terminal (Catppuccin Mocha) |

### CLI Tools (via Brewfile)

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

## Prerequisites

- macOS
- [Homebrew](https://brew.sh) — install it first if you don't have it:
  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- Xcode Command Line Tools:
  ```sh
  xcode-select --install
  ```

## Install

```sh
git clone https://github.com/AlisinaDevelo/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script is idempotent — safe to run again after pulling updates.

After install, run `p10k configure` to set up your prompt style.

## Directory Structure

```
dotfiles/
├── alacritty/
│   └── alacritty.toml      # Terminal appearance + Catppuccin Mocha
├── git/
│   └── .gitconfig          # Git aliases, delta pager, sensible defaults
├── tmux/
│   └── .tmux.conf          # Tmux keybinds, status bar, TPM plugins
├── zsh/
│   └── .zshrc              # Shell config, aliases, tool integrations
├── Brewfile                # All Homebrew dependencies
└── install.sh              # Bootstrap script
```

## Keybindings

### Tmux (prefix: `Ctrl-b`)

| Key | Action |
|-----|--------|
| `|` | Split horizontally |
| `-` | Split vertically |
| `h/j/k/l` | Navigate panes (vim-style) |
| `H/J/K/L` | Resize panes |
| `r` | Reload config |

### Shell Aliases

| Alias | Expands To |
|-------|-----------|
| `ls` | `eza --icons` |
| `ll` | `eza -lah --icons` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gco` | `git checkout` |
| `glg` | `git log --oneline --graph --all` |

## Updating

```sh
cd ~/dotfiles
git pull
./install.sh
```

## License

MIT
