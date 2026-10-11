# dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Portable interactive development configuration for macOS, Linux, WSL2, and Windows. The installers are preview-first, preserve existing files by default, and are verified by a local pipeline rather than GitHub Actions.

This repository owns shell, terminal, Git, tmux, PowerShell, and Neovim behavior. The private `workstation-blueprint` repository owns the larger machine package stack, security profiles, recovery runbooks, and the pinned revision of these public dotfiles.

## Quick Start

### macOS or Linux

Prerequisites: Git and [Homebrew](https://brew.sh).

```sh
git clone https://github.com/AlisinaDevelo/dot-files.git "$HOME/Developer/dev/dotfiles"
cd "$HOME/Developer/dev/dotfiles"

# Inspect only. This is the default and changes nothing.
./install.sh

# Apply packages, pinned shell dependencies, and safe symlinks.
./install.sh --apply

./scripts/setup-repo.sh
./scripts/doctor.sh
```

Use `./install.sh --apply --links-only` when packages are managed elsewhere. If a destination already exists, the installer preserves it and exits with status 2. After reviewing the path, `--backup-existing` moves it to a timestamped backup before linking.

### Windows

Prerequisites: PowerShell 7, Scoop, winget, and Windows Developer Mode for unprivileged symlinks.

```powershell
git clone https://github.com/AlisinaDevelo/dot-files.git "$HOME\Developer\dev\dotfiles"
Set-Location "$HOME\Developer\dev\dotfiles"

# Preview, then apply.
.\install.ps1
.\install.ps1 -Apply
```

The PowerShell installer never downloads and executes a package-manager bootstrap script. Install Scoop from its official instructions first, review the preview, and then apply the plan.

## What Is Managed

| Area | Configuration | Highlights |
| --- | --- | --- |
| Shell | `zsh/`, `powershell/` | Powerlevel10k, Oh My Posh, history, completion, portable user-tool paths |
| Terminal | `alacritty/`, `windows-terminal/` | Cross-platform key bindings, Meslo Nerd Font, Catppuccin palette |
| Multiplexer | `tmux/` | Vim navigation, persistence, guarded TPM startup |
| Git | `git/` | Delta, rebase workflow, aliases, machine-local identity include |
| Editor | `nvim/` | LazyVim, 64 locked plugins, polyglot LSP/test/formatting support |
| AI | `ai/`, `nvim/lua/plugins/ai.lua` | Shared coding-agent instructions; Copilot completion and Avante providers |
| Verification | `scripts/`, `.githooks/` | Syntax, formatting, native parsers, installer tests, secret scanning, clean-clone test |

## Safety Model

1. Running either installer without `--apply` or `-Apply` is a read-only preview.
2. Existing files and directories are never replaced implicitly.
3. Explicit backup mode moves conflicts to timestamped paths before creating links.
4. Oh My Zsh, Powerlevel10k, and TPM are installed at immutable Git revisions.
5. Linux font downloads use immutable URLs and verified SHA-256 hashes.
6. Git identity, credentials, API keys, and host-specific policy stay outside the public repository.
7. Neovim plugin revisions are committed in `nvim/lazy-lock.json`.

See [Installation and Recovery](docs/INSTALL.md), [Migration](docs/MIGRATION.md), and [Supply-Chain Policy](docs/SECURITY.md) for the full operating model.

## Git Identity

The tracked Git config includes `~/.gitconfig.local`. Configure identity once per machine:

```sh
git config --file "$HOME/.gitconfig.local" user.name "Your Name"
git config --file "$HOME/.gitconfig.local" user.email "you@example.com"
GIT_CONFIG_GLOBAL="$HOME/.gitconfig.local" gh auth setup-git
```

This prevents a public dotfiles repository from carrying personal email addresses or architecture-specific credential-helper paths.

## Neovim and AI

The macOS/Linux installer also installs shared personal instructions for Codex and
Claude Code. They cover finishing authorized PRs through merge, verification,
visual checks, public contribution etiquette, and cleanup. Claude imports the
shared `AGENTS.md` from a short `CLAUDE.md` wrapper, so the rules stay consistent.
See [Coding-Agent Instructions](docs/AI-INSTRUCTIONS.md) for paths, customization,
loading checks, and the research behind the policy.

The editor keeps one inline completion engine, Copilot, and one unified assistant surface, Avante. Avante chooses a provider in this order:

1. `AVANTE_PROVIDER`
2. OpenCode ACP when `opencode` is available
3. Kimi ACP when `kimi` is available
4. Claude when `ANTHROPIC_API_KEY` is set
5. OpenAI when `OPENAI_API_KEY` is set
6. Copilot fallback

Tool calls always require approval. Provider and model overrides are documented in [Neovim and AI](docs/NEOVIM.md).

The selected LazyVim extras cover C/C++, CMake, containers, .NET, Git, Go, Java, JSON, Markdown, Python, Rust, SQL, Terraform, TOML, TypeScript, YAML, testing, formatting, and refactoring. The lockfile makes that graph reproducible across machines.

## Local Quality Gate

Enable repository hooks once:

```sh
./scripts/setup-repo.sh
```

Run the same full gate at any time:

```sh
./scripts/local-pipeline.sh
```

It checks the working tree, exercises installer preview/apply/conflict/backup behavior in temporary homes, scans for secrets, and repeats validation from a clean local clone.

The pre-commit hook checks staged whitespace and likely secrets; the pre-push hook runs the full pipeline.

## Common Operations

```sh
# Inspect active links, authentication, and command availability.
./scripts/doctor.sh

# Preview updates after pulling.
git pull --ff-only
./install.sh

# Apply only configuration links.
./install.sh --apply --links-only

# Apply and safely migrate existing destinations.
./install.sh --apply --links-only --backup-existing
```

For the full workstation, use the private blueprint. It pins this repository by commit and layers machine profiles such as builder, AI, defender, and isolated security lab on top.

## Layout

```text
.
|-- .githooks/             local pre-commit and pre-push gates
|-- ai/                    shared Codex and Claude Code working preferences
|-- alacritty/             portable terminal configuration
|-- docs/                  installation, migration, editor, and security guides
|-- git/                   public Git behavior and local-config example
|-- manifests/             immutable third-party source revisions and hashes
|-- nvim/                  LazyVim configuration and plugin lockfile
|-- powershell/            Windows shell profile
|-- scripts/               doctor, tests, validation, and local pipeline
|-- tmux/                  terminal multiplexer configuration
|-- windows-terminal/      Windows Terminal settings
|-- zsh/                   macOS/Linux/WSL shell configuration
|-- Brewfile               cross-platform Homebrew formulae
|-- Brewfile.macos         macOS casks and fonts
|-- install.ps1            preview-first Windows installer
`-- install.sh             preview-first macOS/Linux installer
```

## License

MIT
