# Installation and Recovery

## Choose the Entry Point

Use this public repository directly when you only need the interactive development environment.

Use the private `workstation-blueprint` when rebuilding a complete machine: it owns package profiles, security tooling, editor extensions, private runbooks, and a pinned dotfiles revision.

The direct path is appropriate for:

- A temporary Linux environment or WSL2 instance.
- A machine where another system already manages most packages.
- Testing shell and editor changes in isolation.

The private blueprint is the preferred path for a permanent laptop.

## macOS Preparation

1. Install Xcode Command Line Tools.
2. Install Homebrew from its official site and inspect its installer before execution.
3. Authenticate GitHub CLI after the package layer is present.
4. Clone this repository under `~/Developer/dev/dotfiles`.

Run a read-only preview first:

```sh
./install.sh
```

The preview reports the platform, package mode, conflict policy, and every managed destination. It performs no network access and creates no files.

Apply after review:

```sh
./install.sh --apply
```

This applies `Brewfile`, `Brewfile.macos`, immutable shell dependencies, verified fonts where applicable, and configuration symlinks.

## Linux and WSL2 Preparation

The installer supports Linux when Homebrew for Linux is already available. Distribution package managers remain useful for system-level dependencies such as compilers, `fontconfig`, desktop integration, and graphics libraries.

The Linux path applies the shared Brewfile, installs MesloLGS font files from an immutable upstream revision, verifies each SHA-256 digest, and refreshes the font cache when `fc-cache` exists.

For a links-only environment:

```sh
./install.sh --apply --links-only
```

This is useful inside short-lived containers and machines whose packages are managed by the private blueprint.

## Windows Preparation

Install PowerShell 7, Scoop, and winget from official sources. Enable Developer Mode so a standard user can create symbolic links. Then run:

```powershell
.\install.ps1
.\install.ps1 -Apply
```

The script requires Scoop rather than executing a remote bootstrap payload. It installs terminal, editor, CLI, local validation, AI, and infrastructure tools through Scoop and winget, then links the Windows configurations.

## Existing Configuration

An existing destination is a migration decision, not an installer error to hide. Default apply mode preserves the path, links everything else it safely can, and exits with status 2.

Inspect the report:

```sh
./scripts/doctor.sh
```

After confirming the tracked version should become active, use explicit backup mode:

```sh
./install.sh --apply --links-only --backup-existing
```

Backups are siblings of the original path and include a timestamp. The installer never deletes them.

## Machine-Local Configuration

The public Git config includes `~/.gitconfig.local`. Keep these values there:

- User name and email.
- GitHub credential helper configuration.
- Corporate proxies or signing policy.
- Machine-specific include paths.

Keep shell secrets and host-only environment variables in `~/.zshrc.local` or `~/.powershell.local.ps1`. Never put API keys in the tracked profiles.

## Post-Install Verification

```sh
./scripts/setup-repo.sh
./scripts/doctor.sh
./scripts/local-pipeline.sh
```

Then:

1. Restart the terminal.
2. Run `p10k configure` if the prompt has not been configured.
3. Start tmux and install TPM plugins with prefix followed by `I`.
4. Open Neovim and allow Mason packages to complete.
5. Authenticate Copilot with `:Copilot auth` when needed.
6. Select or verify the Avante provider with `:AvanteSwitchProvider`.

## Recovery Test

The local pipeline creates temporary homes and proves four installer properties:

- Preview mode is read-only.
- Fresh installation creates the intended links.
- Conflicting files and directories remain unchanged by default.
- Explicit backup mode preserves old content before linking.

It then repeats repository validation from a clean local clone. This is the local replacement for unavailable GitHub Actions.
