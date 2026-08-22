#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  printf 'Secret check requires a Git worktree.\n' >&2
  exit 1
}

bad_names="$(git ls-files | grep -Ei '(^|/)(\.env($|\.)|auth\.json$|mcp-auth\.json$|credentials([^/]*$|/)|[^/]+\.(pem|key|p12|pfx|kdbx)$)' || true)"
if [ -n "$bad_names" ]; then
  printf 'Prohibited credential-like filenames are tracked:\n%s\n' "$bad_names" >&2
  exit 1
fi

# Print filenames only. Secret material must never be copied into logs.
suspect_files="$({
  git grep --cached -IlE -- '-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----' -- ':!scripts/check-secrets.sh' || true
  git grep --cached -IlE -- 'gh[pousr]_[A-Za-z0-9_]{30,}' -- ':!scripts/check-secrets.sh' || true
  git grep --cached -IlE -- 'AKIA[0-9A-Z]{16}' -- ':!scripts/check-secrets.sh' || true
  git grep --cached -IlE -- 'sk-[A-Za-z0-9_-]{20,}' -- ':!scripts/check-secrets.sh' || true
  git grep --cached -IlE -- 'xox[baprs]-[A-Za-z0-9-]{20,}' -- ':!scripts/check-secrets.sh' || true
} | sort -u)"

if [ -n "$suspect_files" ]; then
  printf 'Likely credential material found in:\n%s\n' "$suspect_files" >&2
  exit 1
fi

printf 'No tracked credential filenames or high-confidence token patterns found.\n'
