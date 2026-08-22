#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_BASE="${TMPDIR:-/tmp}"
TEMP_BASE="${TEMP_BASE%/}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/dotfiles-pipeline.XXXXXX")"

cleanup() {
  case "$TEMP_ROOT" in
    "$TEMP_BASE"/dotfiles-pipeline.*) rm -rf -- "$TEMP_ROOT" ;;
    *) printf 'Refusing to remove unexpected path: %s\n' "$TEMP_ROOT" >&2 ;;
  esac
}
trap cleanup EXIT HUP INT TERM

cd "$ROOT"

printf '==> Working-tree validation\n'
./scripts/validate.sh
./scripts/test-install.sh

if command -v gitleaks >/dev/null 2>&1; then
  printf '==> Gitleaks working-directory scan\n'
  gitleaks dir --redact --no-banner .
else
  printf 'WARN: gitleaks unavailable; the built-in secret scan still ran.\n' >&2
fi

printf '==> Clean-clone validation\n'
git clone --quiet --no-local "$ROOT" "$TEMP_ROOT/repository"
(
  cd "$TEMP_ROOT/repository"
  ./scripts/setup-repo.sh
  ./scripts/validate.sh
  ./scripts/test-install.sh
)

printf 'Local pipeline passed in the working tree and a clean clone.\n'
