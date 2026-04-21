# Claude Code Dotfiles

Personal Claude Code configurations including custom commands, skills, and agents.

## Installation

Symlink the `.claude` directory to your home folder:

```bash
ln -s ~/Desktop/dotfiles/.claude ~/.claude
```

Or copy specific files to your existing `~/.claude/` directory.

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

## Requirements

Some commands require specific tools:

- `/lint`, `/fix-types`: `uv` package manager with `ruff` and `pyrefly`
- `/architecture`: `claude-mermaid` MCP plugin
- `/tester`: Python project with FastAPI structure
