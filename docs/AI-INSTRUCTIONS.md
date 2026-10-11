# Coding-Agent Instructions

`ai/AGENTS.md` contains reusable personal working agreements. `ai/CLAUDE.md`
imports that file and adds Claude-specific context handling. Repository build
commands, architecture, inventories, and deployment instructions belong in each
project's own instructions rather than this global profile.

## Install and Inspect

On macOS, Linux, or WSL, the normal installer previews these three destinations:

| Source | Default destination |
| --- | --- |
| `ai/AGENTS.md` | `~/.codex/AGENTS.md` |
| `ai/AGENTS.md` | `~/.claude/AGENTS.md` |
| `ai/CLAUDE.md` | `~/.claude/CLAUDE.md` |

```sh
./install.sh --links-only
./install.sh --apply --links-only
./scripts/doctor.sh
```

`CODEX_HOME` and `CLAUDE_CONFIG_DIR` select alternate configuration directories.
The installer preserves conflicting instructions unless explicit backup mode is
used. It creates the shared file beside Claude's wrapper so the literal
`@AGENTS.md` import also resolves after installation.

On Windows, copy the same three sources to the equivalent user directories or
to the directories selected by those environment variables. The PowerShell
installer currently manages the terminal/editor profiles, not these agent links.

Start a new agent session after updating the files. Codex loads global guidance
once at startup; an existing `AGENTS.override.md` can shadow it. Claude's
`--bare` and `--safe-mode` modes intentionally skip normal instruction discovery.
These Markdown files guide behavior; they do not grant tool permissions or bypass
branch protection, required approvals, or organizational policy.

For Codex, ask a new session to summarize its current instructions. For Claude,
use `/memory` or `/context` to inspect active sources and check the imported
agreements. Confirm the rules about PR completion and cleanup are present, rather
than assuming a file's existence proves it was loaded.

## PR Completion

The global agreement distinguishes authorization from verification: authorized
work continues through checks, review, fixes, and merge when the repository permits
it. An open PR, queued auto-merge, or pending check is an intermediate state.
Draft-only instructions, missing maintainer authority, and required repository
gates still apply. A repository that intentionally uses a local quality gate can
provide valid verification without hosted CI; record what actually ran.

## Sources and Maintenance

The profile modernizes the previous laptop's two files. It retains public
contribution etiquette, truthful validation, and scoped cleanup while removing
old project maps, a fixed older model override, mandatory unavailable tooling,
and claims to override higher-priority instructions.

- [Codex instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [OpenAI guidance on modern agent instructions](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra)
- [Claude memory, imports, and instruction scopes](https://code.claude.com/docs/en/memory)
- [Claude Code best practices](https://code.claude.com/docs/en/best-practices)
- [Claude prompting guidance](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Karpathy's evaluation and simplicity principles in autoresearch](https://github.com/karpathy/autoresearch/blob/master/program.md)

Keep the shared policy short and review it when agent behavior changes. Prefer
concrete fixes for observed failures over adding general instructions repeatedly.
