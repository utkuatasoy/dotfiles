# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a personal dotfiles repository containing Claude Code configurations, custom commands, skills, and agents. These configurations are designed to be symlinked or copied to `~/.claude/` for global availability across all projects.

## Structure

```
.claude/
├── commands/       # Slash commands invoked with /command-name
├── skills/         # Reusable skill definitions (always active)
└── agents/         # Custom agent configurations
```

## Available Commands

| Command | Purpose |
|---------|---------|
| `/init` | Initialize project (venv, VS Code config, CLAUDE.md, detect stack) |
| `/commit` | Conventional commits (single-line, no emoji, splits large changes) |
| `/lint` | Python linting with Ruff (format + check + fix) |
| `/tester` | Generate pytest test suites for FastAPI projects |
| `/fix-types` | Run Pyrefly type checker and fix errors |
| `/overview` | Generate comprehensive OVERVIEW.md documentation |
| `/readme` | Generate README.md documentation |
| `/architecture` | Generate architecture diagrams with SVG rendering |
| `/linkedin-post` | Generate technical LinkedIn posts from URLs |
| `/cache-cleaner` | Remove Python `__pycache__` directories |
| `/ieee-paper` | Generate IEEE-formatted LaTeX components (figures, tables, references, etc.) |
| `/update` | Update documentation based on recent git diff |
| `/deslop` | Remove AI-generated code slop from branch changes |

## Available Skills

| Skill | Purpose |
|-------|---------|
| `commit` | Conventional commit rules (no emoji, single-line, no co-author) |
| `clean-code` | Avoid AI slop: no obvious comments, no excessive checks, minimal code |
| `fastapi` | FastAPI/Python conventions and patterns |
| `find-bugs` | Find bugs, security issues, and code quality problems |
| `architecture-diagrams` | Generate Mermaid architecture diagrams for codebase |
| `latex` | LaTeX Q&A assistant for IEEE papers (troubleshooting, tips, syntax) |

## Custom Agents

- **test-engineer**: Creates comprehensive pytest test suites for FastAPI Python backends with proper mocking, fixtures, and coverage configuration.

## Installation

To use these configurations globally:

```bash
ln -s ~/Desktop/dotfiles/.claude ~/.claude
```

Or copy specific files to your existing `~/.claude/` directory.
