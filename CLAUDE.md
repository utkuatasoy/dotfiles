# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a personal dotfiles repository containing agent configurations: Claude Code commands, skills, agents and
hooks under `.claude/`, plus the pi harness under `pi/` (launcher, zsh helpers, extensions and config templates for
self-hosted, OpenAI-compatible model endpoints). These configurations are designed to be symlinked or copied to
`~/.claude/` and `~/.pi/agent/` for global availability across all projects.

## Structure

```
.claude/
├── commands/       # Slash commands invoked with /command-name
├── skills/         # Reusable skill definitions (always active)
└── agents/         # Custom agent configurations

pi/                 # pi coding agent harness (own package.json and README)
├── run_pi.sh       # launcher: resolves the model, loads extensions, starts pi
├── shell/pi.zsh    # zsh function `pi` plus completion
├── wrappers/       # HUD footer extension
├── extensions/     # git-guard.ts — pi port of .claude/hooks/commit-guard.py
└── config/         # *.example templates only; real hosts/keys are gitignored
```

## Available Commands

| Command | Purpose |
|---------|---------|
| `/init` | Initialize project (venv, VS Code config, CLAUDE.md, detect stack) |
| `/commit` | Conventional commits (single-line, no emoji, efficiency-aware grouping) |
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
| `/deep-research` | Fetch a URL and produce a comprehensive technical analysis document |

## Available Skills

| Skill | Purpose |
|-------|---------|
| `commit` | Conventional commit rules (no emoji, single-line, efficiency-aware) |
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
ln -s ~/Desktop/code-personal/dotfiles/.claude ~/.claude
```

Or copy specific files to your existing `~/.claude/` directory.

## pi Harness

`pi/` wraps the pi coding agent for private, OpenAI-compatible endpoints. `pi/README.md` is the reference for it
(setup, model picker, thinking configuration, git guard, VS Code image paste); do not duplicate that content here.
Two things matter when editing this repo:

- **Never commit real endpoints, keys or model ids.** Only `config/*.example` files are tracked; `config/models.json`,
  `config/aliases`, `config/default-model` and `config/last-model` are gitignored and must stay that way. Keep
  company names and internal hostnames out of the examples — use placeholders like `<PROD_HOST>` and
  `onprem-prod`.
- **The guard rules live in two places.** `extensions/git-guard.ts` (pi) is a port of `.claude/hooks/commit-guard.py`
  (Claude Code): commit-message rules are identical, and both must change together when the rules change. The pi
  version also prompts before `git push`, while the Python hook only guards commits.
