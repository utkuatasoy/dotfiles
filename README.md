# Claude Code & pi Dotfiles

Personal agent configurations: Claude Code commands, skills, agents and hooks, plus the
[pi coding agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) harness for self-hosted,
OpenAI-compatible model endpoints.

## Installation

Symlink the `.claude` directory to your home folder:

```bash
ln -s ~/Desktop/code-personal/dotfiles/.claude ~/.claude
```

Or copy specific files to your existing `~/.claude/` directory.

The pi harness in `pi/` installs separately — see [pi Harness](#pi-harness-on-prem-models).

## Available Commands

| Command | Description |
|---------|-------------|
| `/init` | Initialize project (venv, VS Code config, CLAUDE.md, detect stack) |
| `/commit` | Conventional commits (single-line, no emoji, auto-splits large changes) |
| `/lint` | Python linting with Ruff (format + check + fix) |
| `/tester <path>` | Generate pytest test suites for FastAPI projects |
| `/fix-types` | Run Pyrefly type checker and fix errors iteratively |
| `/overview` | Generate comprehensive OVERVIEW.md for a repository |
| `/readme` | Generate README.md documentation |
| `/architecture` | Generate architecture diagrams with SVG rendering |
| `/linkedin-post <url>` | Generate technical LinkedIn posts from blog/paper URLs |
| `/cache-cleaner` | Remove Python `__pycache__` directories recursively |
| `/ieee-paper <component>` | Generate IEEE-formatted LaTeX components (figures, tables, refs) |
| `/update <file>` | Update documentation based on recent git diff |
| `/deslop` | Remove AI-generated code slop from branch changes |
| `/deep-research <url> [lang]` | Fetch a URL and produce a comprehensive technical analysis document |
| `/ascii-diagram` | Convert architecture descriptions to ASCII art diagrams |
| `/sync-frontend` | Analyze backend changes and update corresponding frontend files |
| `/self-review` | Adversarially review session changes for security, correctness, edge cases, and test gaps — then fix them |

## Available Skills

| Skill | Description |
|-------|-------------|
| `commit` | Conventional commit rules (no emoji, single-line, no co-author) |
| `clean-code` | Avoid AI slop: no obvious comments, no excessive checks, minimal code |
| `fastapi` | FastAPI/Python conventions and patterns |
| `find-bugs` | Find bugs, security issues, and code quality problems |
| `architecture-diagrams` | Generate Mermaid architecture diagrams for codebase |
| `latex` | LaTeX Q&A assistant for IEEE papers (troubleshooting, tips, syntax) |

## Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `session-context.sh` | `SessionStart` | Auto-loads `OVERVIEW.md` (or falls back to `README.md` / `CLAUDE.md`) plus the last 5 git commits into Claude's context at session start |
| `commit-guard.py` | `PreToolUse` (Bash) | Blocks any `git commit` that violates the conventional-commit rules: no co-author attribution, no "Generated with" / Claude Code tags, no robot emoji, no multiline body, must start with a conventional type prefix |

## Custom Agents

### test-engineer

Creates comprehensive pytest test suites for FastAPI Python backends:

- Generates proper directory structure mirroring source code
- Creates conftest.py with settings mocks
- Includes pytest.ini and .coveragerc configurations
- Follows AAA pattern (Arrange, Act, Assert)
- Supports async testing with pytest-asyncio

## pi Harness (on-prem models)

`pi/` is a self-contained harness around the pi coding agent for private, OpenAI-compatible endpoints
(vLLM / SGLang / Dynamo style gateways). It keeps endpoints and keys out of git: only `*.example` templates are
tracked, and the real `config/models.json` and `config/aliases` stay local (and gitignored).

What it adds on top of stock pi:

| Feature | Description |
|---------|-------------|
| Model aliases | `pi ds`, `pi flash`, `pi glm` instead of long `--model provider/model-id` flags |
| Model picker | Bare `pi` lists the aliases with their live endpoint status; `Enter` starts, `d` also sets the default |
| Persistent default | `pi use <alias>` / `pi use --clear`, with a "first reachable endpoint" fallback |
| Status probing | `pi models` / `pi help` call each endpoint's `/v1/models` in parallel and report `ok`, `bad key`, `down`, `key not set` |
| HUD footer | Two-line status footer: model, context bar, git branch, running tool, token counts (`/hud` toggles it) |
| Git guard | Commit-message rules and push approval enforced as a pi extension — the pi port of `commit-guard.py` |
| Package resources | The superpowers skills and the subagent tools are loaded by path, so extension discovery can stay off (`-ne`) and the system prompt stays small |

The harness has its own reference — setup, model-picker keys, thinking configuration, the git guard rules and the
VS Code `cmd+v` image-paste fix all live in [`pi/README.md`](pi/README.md).

Quick start:

```bash
cd pi && npm install
cp config/models.json.example config/models.json   # fill in hosts, model ids, context windows
cp config/aliases.example config/aliases           # aliases, probe urls, API key env vars

mkdir -p ~/.pi/agent && ln -sfn "$PWD/config/models.json" ~/.pi/agent/models.json
```

Then export the API keys, `source <harness-root>/shell/pi.zsh` from `~/.zshrc`, and run `pi help`.

## Structure

```
.claude/
├── settings.json       # Global Claude Code settings (registers hooks)
├── hooks/              # Shell/python hooks invoked by Claude Code events
│   ├── session-context.sh
│   └── commit-guard.py
├── commands/           # Slash commands (/command-name)
│   ├── init.md
│   ├── commit.md
│   ├── lint.md
│   ├── tester.md
│   ├── fix-types.md
│   ├── overview.md
│   ├── readme.md
│   ├── architecture.md
│   ├── linkedin-post.md
│   ├── cache-cleaner.md
│   ├── ieee-paper.md
│   ├── update.md
│   ├── deslop.md
│   ├── deep-research.md
│   ├── ascii-diagram.md
│   ├── sync-frontend.md
│   └── self-review.md
├── skills/             # Reusable skill definitions
│   ├── commit.md
│   ├── clean-code.md
│   ├── fastapi.md
│   ├── find-bugs.md
│   ├── architecture-diagrams.md
│   └── latex.md
└── agents/             # Custom agent configurations
    └── test-engineer.md
```

```
pi/                      # pi harness for on-prem endpoints (own README, own package.json)
├── run_pi.sh            # launcher: resolves the model, loads extensions, starts pi
├── shell/pi.zsh         # zsh function `pi` (picker, help, models, use, pick, config, raw) plus completion
├── wrappers/hud.ts      # HUD footer extension
├── extensions/
│   └── git-guard.ts     # commit rules + push approval as a tool_call hook
└── config/
    ├── models.json.example
    └── aliases.example
```

## Requirements

Some commands require specific tools:

- `/lint`, `/fix-types`: `uv` package manager with `ruff` and `pyrefly`
- `/architecture`: `claude-mermaid` MCP plugin
- `/tester`: Python project with FastAPI structure
- `pi/`: Node.js >= 22, npm, git, curl and zsh
