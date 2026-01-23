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

## Available Skills

| Skill | Description |
|-------|-------------|
| `commit` | Conventional commit rules (no emoji, single-line, no co-author) |
| `architecture-diagrams` | Generate Mermaid architecture diagrams for codebase |
| `latex` | LaTeX Q&A assistant for IEEE papers (troubleshooting, tips, syntax) |

## Custom Agents

### test-automation-engineer

Creates comprehensive pytest test suites for FastAPI Python backends:

- Generates proper directory structure mirroring source code
- Creates conftest.py with settings mocks
- Includes pytest.ini and .coveragerc configurations
- Follows AAA pattern (Arrange, Act, Assert)
- Supports async testing with pytest-asyncio

## Structure

```
.claude/
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
│   └── update.md
├── templates/          # Project templates
│   └── fastapi-rules.md
├── skills/             # Reusable skill definitions
│   ├── commit.md
│   ├── architecture-diagrams.md
│   └── ieee-latex-paper.md
└── agents/             # Custom agent configurations
    └── test-automation-engineer.md
```

## Requirements

Some commands require specific tools:

- `/lint`, `/fix-types`: `uv` package manager with `ruff` and `pyrefly`
- `/architecture`: `claude-mermaid` MCP plugin
- `/tester`: Python project with FastAPI structure
