#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null
git -C "$ROOT" config core.hooksPath .githooks

printf 'Configured local Git hooks for %s\n' "$ROOT"
printf 'Pre-commit checks whitespace and secrets; pre-push runs the full local pipeline.\n'
