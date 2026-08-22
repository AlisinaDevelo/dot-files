# Migration

## Ownership Boundary

The public repository carries interactive behavior that can safely be visible: shells, terminal themes, key mappings, editor configuration, Git defaults, and local validation.

The private workstation blueprint carries machine inventory, security profiles, private runbooks, package layers beyond the dotfiles, and the exact public commit to restore. Credentials belong in neither repository.

## Before Leaving a Machine

1. Run the dotfiles local pipeline.
2. Run the private blueprint snapshot and doctor.
3. Push clean, reviewed commits from both repositories.
4. Confirm the private blueprint pins the newest public dotfiles commit.
5. Export or synchronize password-manager, SSH, signing, and recovery material through their approved channels.
6. Record any software that is intentionally host-only.

Do not archive home directories full of tokens as a substitute for a migration plan.

## Bringing Up a New Machine

1. Install the operating system and apply updates.
2. Establish disk encryption, account recovery, and password-manager access.
3. Authenticate GitHub with the minimum required scopes.
4. Clone the private workstation blueprint.
5. Review its bootstrap preview and apply the chosen profile.
6. Let the blueprint clone the pinned public dotfiles revision.
7. Configure `~/.gitconfig.local` and host-only shell settings.
8. Run both doctors and both local pipelines.

The public installer is still safe to run directly. Preview it before every apply.

## Migrating an Existing Config Directory

The doctor reports a failure when a managed destination is a regular file or directory. This is expected when adopting the repository on a machine that already has hand-managed configuration.

Review the difference first. For Neovim, compare at least:

- `lazyvim.json` extras.
- Custom files under `lua/config` and `lua/plugins`.
- The plugin lockfile.
- Any local authentication or provider configuration.

When the tracked version is ready to become active:

```sh
./install.sh --apply --links-only --backup-existing
./scripts/doctor.sh
```

The original directory remains beside the new link with a timestamped `.backup` suffix. Keep it until the new configuration has survived normal work.

## Rollback

1. Close applications using the configuration.
2. Remove only the symlink created by the installer.
3. Move the timestamped backup back to its original name.
4. Reopen the application and verify behavior.
5. Record what failed before attempting another migration.

The installer does not automate rollback because choosing among multiple backups is a human decision.

## Drift Control

Run `./scripts/doctor.sh` after OS upgrades, package-manager migrations, architecture changes, or edits made by third-party installers.

It detects missing commands, unexpected link targets, a nested Neovim link left by the old installer behavior, Git identity state, GitHub authentication, and available AI tools.

Changes made directly under a symlinked tracked directory are repository changes. Changes in `.zshrc.local`, `.powershell.local.ps1`, `.gitconfig.local`, caches, plugin data, and API environments remain host-local.
