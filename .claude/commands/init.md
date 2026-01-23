# Command: Project Initializer

Initialize and understand a new project. Sets up development environment, VS Code configurations, and generates documentation for codebase understanding.

---

## Usage

```bash
/init
/init --skip-venv
/init --skip-docs
```

---

## What This Command Does

### 1) Detect Project Type and Structure

Analyze the project root to identify:

```bash
ls -la
```

Look for indicators:
- `pyproject.toml` or `requirements.txt` → Python project
- `package.json` → Node.js/Next.js project
- `Cargo.toml` → Rust project
- `go.mod` → Go project
- `src/` directory → Source code location
- `app/` directory → Application code
- `tests/` directory → Test files

### 2) Analyze Tech Stack

For **Python projects**, check `pyproject.toml` or `requirements.txt` for:
- FastAPI/Flask/Django (web framework)
- LangChain/LangGraph (AI/LLM)
- SQLAlchemy/asyncpg (database)
- pytest (testing)

For **Node.js projects**, check `package.json` for:
- Next.js/React/Vue (frontend framework)
- Express/Fastify (backend)
- TypeScript usage

### 3) Set Up Virtual Environment (Python projects)

If `pyproject.toml` exists and `.venv` does not:

```bash
uv venv
uv sync
```

If `.venv` exists, skip or ask user.

### 4) Create/Update VS Code Configuration

#### `.vscode/settings.json`

Create if not exists with Python-optimized settings:

```json
{
    "files.trimTrailingWhitespace": true,
    "editor.formatOnSave": true,
    "files.insertFinalNewline": true,
    "[python]": {
        "editor.tabSize": 4,
        "editor.insertSpaces": true,
        "editor.rulers": [100],
        "editor.defaultFormatter": "charliermarsh.ruff"
    },
    "python.autoComplete.extraPaths": ["${workspaceFolder}/src"],
    "python.analysis.extraPaths": ["${workspaceFolder}/src"]
}
```

#### `.vscode/launch.json`

Create debug configurations based on detected stack:

**For FastAPI projects** (detect via `fastapi` in dependencies):

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug FastAPI",
            "type": "debugpy",
            "request": "launch",
            "program": "${workspaceFolder}/src/app/main.py",
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}",
            "env": {
                "PYTHONPATH": "${workspaceFolder}/src"
            },
            "justMyCode": false
        },
        {
            "name": "Debug Current File",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}",
            "env": {
                "PYTHONPATH": "${workspaceFolder}/src"
            },
            "justMyCode": false
        },
        {
            "name": "Debug Tests",
            "type": "debugpy",
            "request": "launch",
            "module": "pytest",
            "args": ["-v", "-s"],
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}",
            "env": {
                "PYTHONPATH": "${workspaceFolder}/src"
            },
            "justMyCode": false
        }
    ]
}
```

**For Next.js projects** (detect via `next` in dependencies):

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Next.js: debug server-side",
            "type": "node-terminal",
            "request": "launch",
            "command": "npm run dev"
        },
        {
            "name": "Next.js: debug client-side",
            "type": "chrome",
            "request": "launch",
            "url": "http://localhost:3000"
        }
    ]
}
```

**For monorepo (FastAPI + Next.js)**:

Combine both configurations and add compound launch.

### 5) Create CLAUDE.md (if not exists)

Generate project-specific CLAUDE.md with:
- Project purpose (from README or package description)
- Directory structure
- Key commands (run, test, build)
- Tech stack summary
- Coding conventions based on detected stack

**For FastAPI projects**, include the FastAPI rules from `~/.claude/templates/fastapi-rules.md`.

Template:

```markdown
# CLAUDE.md

## Project Overview
[Brief description from README/pyproject.toml]

## Tech Stack
- Backend: [FastAPI/Django/etc.]
- Frontend: [Next.js/React/etc.]
- Database: [PostgreSQL/SQLite/etc.]
- Package Manager: [uv/npm/etc.]

## Directory Structure
[Tree of main directories]

## Development Commands

### Setup
```bash
uv sync  # or npm install
```

### Run
```bash
uv run python src/app/main.py  # or npm run dev
```

### Test
```bash
uv run pytest  # or npm test
```

### Lint
```bash
uv run ruff check . --fix
```

## Coding Conventions

[Include content from ~/.claude/templates/fastapi-rules.md for FastAPI projects]
```

### 6) Generate OVERVIEW.md (optional, if --skip-docs not specified)

Run the `/overview` command logic to create comprehensive documentation.

### 7) Check for .env Configuration

If `.env.example` exists but `.env` does not:
- Warn the user
- Offer to copy `.env.example` to `.env`

```bash
cp .env.example .env
```

### 8) Summary Report

Output a summary of what was done:

```
Project Initialization Complete
================================
Project Type: FastAPI + Python
Package Manager: uv

Created/Updated:
  ✓ .vscode/settings.json
  ✓ .vscode/launch.json
  ✓ CLAUDE.md
  ✓ OVERVIEW.md

Environment:
  ✓ Virtual environment: .venv
  ✓ Dependencies installed

Next Steps:
  1. Review and update .env file
  2. Run: uv run python src/app/main.py
  3. Debug with VS Code: F5 → "Debug FastAPI"
```

---

## Detection Logic

### Entry Point Detection (FastAPI)

Search for main.py or app entry points:

```bash
find . -name "main.py" -path "*/app/*" | head -1
find . -name "main.py" -path "*/src/*" | head -1
```

Common patterns:
- `src/app/main.py`
- `src/main.py`
- `app/main.py`
- `main.py`

Adjust `launch.json` program path accordingly.

### Source Root Detection

Check for `src/` directory:
- If exists: PYTHONPATH should include `${workspaceFolder}/src`
- If not: PYTHONPATH should be `${workspaceFolder}`

---

## Flags

| Flag | Description |
|------|-------------|
| `--skip-venv` | Skip virtual environment creation |
| `--skip-docs` | Skip OVERVIEW.md generation |
| `--force` | Overwrite existing configurations |

---

## Notes

- Never overwrite existing files without `--force` flag
- Always backup existing configurations before modifying
- Ask user before making changes to critical files
- Respect existing project conventions
