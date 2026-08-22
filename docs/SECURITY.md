# Supply-Chain and Secret Policy

## Trust Boundaries

The repository can make a machine productive, but every package manager and plugin ecosystem remains a trust boundary. Portability does not mean executing the newest upstream code without review.

Controls in this repository:

- Preview-first installers.
- No remote script piped directly into a shell or PowerShell evaluator.
- Immutable revisions for Oh My Zsh, Powerlevel10k, and TPM.
- SHA-256 verification for Linux font downloads.
- A committed Neovim plugin lockfile.
- A built-in high-confidence secret scan plus Gitleaks.
- Local hooks and a clean-clone pipeline.
- Explicit permission prompts for Avante tools.

## What Is Not Fully Locked

Homebrew, Scoop, winget, Mason packages, and operating-system updates resolve from their package repositories. Their manifests express intent but are not a complete binary provenance lock.

Before a major update:

1. Review package-manager changes and repository ownership.
2. Snapshot current versions with the private workstation blueprint.
3. Apply updates in a controlled window.
4. Run local pipelines and representative application smoke tests.
5. Retain a recovery path for security-sensitive tools.

## Updating Immutable Sources

`manifests/sources.lock` contains upstream URLs, Git commits, and font hashes. Update it as one reviewed change:

1. Confirm the canonical upstream repository.
2. Inspect release notes and commits between old and new revisions.
3. Recompute each font hash from the immutable new URL.
4. Test a fresh temporary installation.
5. Run the full local pipeline.

Never replace an immutable revision with a mutable `main`, `master`, or `latest` URL in the installer.

## Secret Placement

Allowed host-only locations include:

- A password manager or platform keychain.
- `~/.gitconfig.local` for identity and credential-helper declarations.
- `~/.zshrc.local` or `~/.powershell.local.ps1` for non-secret host settings.
- Session environment variables supplied by a secret manager.

Do not track:

- API keys, access tokens, private keys, auth databases, or recovery codes.
- `.env` files containing credentials.
- Tool-specific auth JSON.
- Corporate endpoints or private machine policy unless intentionally sanitized.

The pre-commit check inspects tracked filenames and common high-confidence token formats. Gitleaks expands that coverage in the full local pipeline. No scanner proves absence; review still matters.

## Security Tooling Boundary

Offensive and forensic tools belong to the private blueprint's isolated security-lab profile, not this public interactive-config repository.

Keep authorization, evidence handling, target scope, and network isolation in the private runbooks. A portable shell should not silently turn every new laptop into an unrestricted lab environment.
