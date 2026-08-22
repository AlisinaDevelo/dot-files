# Neovim and AI

## Design

The editor is a locked LazyVim distribution with a broad language surface and a deliberately narrow AI surface:

- Copilot owns inline completion.
- Avante owns chat, edits, provider switching, and agent-backed workflows.
- OpenCode and Kimi connect through Agent Client Protocol support.
- Claude, OpenAI, Ollama, and Copilot remain selectable providers.

This avoids loading several competing inline completion engines that duplicate network calls, consume memory, and fight over key mappings.

## Provider Selection

Automatic selection follows this order:

1. Explicit `AVANTE_PROVIDER`.
2. `opencode` executable, using the `opencode` ACP provider.
3. `kimi` executable, using the `kimi-cli` ACP provider.
4. `ANTHROPIC_API_KEY`, using `claude`.
5. `OPENAI_API_KEY`, using `openai`.
6. `copilot`.

Override the choice for one shell session:

```sh
export AVANTE_PROVIDER=ollama
export AVANTE_OLLAMA_MODEL=qwen2.5-coder
```

Supported overrides:

| Variable | Purpose |
| --- | --- |
| `AVANTE_PROVIDER` | Provider or ACP provider identifier |
| `AVANTE_CLAUDE_MODEL` | Anthropic model override |
| `AVANTE_OPENAI_MODEL` | OpenAI model override |
| `AVANTE_OLLAMA_ENDPOINT` | Ollama API endpoint |
| `AVANTE_OLLAMA_MODEL` | Local Ollama model |
| `OPENCODE_BIN` | Non-standard OpenCode executable path |
| `KIMI_BIN` | Non-standard Kimi executable path |

Model identifiers change faster than the dotfiles. Leaving a cloud model override unset inherits Avante's current provider default instead of freezing an obsolete model name in public configuration.

## Security Posture

`auto_approve_tool_permissions` is disabled. Agent tools must ask before acting, generated diffs are not applied automatically, and API keys are read only from the environment.

Recommended practice:

- Keep provider credentials in a secret manager or session environment.
- Do not write keys into `.zshrc`, project files, Neovim Lua, or Git history.
- Review agent diffs before applying them.
- Use local Ollama for sensitive source when its model quality is sufficient.
- Keep OpenCode and Kimi permission policy restrictive for unfamiliar repositories.

## Useful Commands

| Command or key | Action |
| --- | --- |
| `:AvanteSwitchProvider` / `<leader>ap` | Select provider |
| `:AvanteModels` / `<leader>am` | Select model |
| `<leader>aa` | Ask about the current context or selection |
| `<leader>ae` | Edit the selected code |
| `<leader>at` | Toggle the assistant panel |
| `<leader>ac` | Clear the current chat |
| `<M-l>` | Accept a Copilot suggestion |
| `<M-w>` | Accept one Copilot word |
| `:Copilot auth` | Authenticate Copilot |

## Language Surface

The selected extras cover C/C++, CMake, Docker, .NET, Git, Go, Java, JSON, Markdown, Python, Rust, SQL, Terraform, TOML, TypeScript, YAML, formatting, tests, rename workflows, Telescope, and structural highlighting.

LazyVim and Mason distinguish editor plugins from external language tools. On the first launch, allow Mason installation to finish before evaluating missing LSP or formatter behavior.

## Updating Deliberately

1. Start from a clean Git working tree.
2. Run `:Lazy sync` and allow native builds to finish.
3. Review `nvim/lazy-lock.json` rather than accepting an opaque dependency jump.
4. Run `./scripts/local-pipeline.sh`.
5. Launch Neovim headlessly or interactively and check `:Lazy`, `:checkhealth`, and one representative file for each language changed.
6. Commit the configuration and lockfile together.

The lockfile is part of the portable system. Do not add it to `.gitignore`.
