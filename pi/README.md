# pi harness for on-prem models

A small, self-contained harness around the [pi coding agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)
for running it against self-hosted, OpenAI-compatible model endpoints (vLLM / SGLang / Dynamo style gateways).

## Overview

Stock pi can already talk to any OpenAI-compatible server through `~/.pi/agent/models.json`.
This repo adds the pieces that make day-to-day use on private endpoints pleasant:

- **Short model aliases.** `pi ds`, `pi flash`, `pi glm` instead of `--model provider/long-model-id`.
- **A picker on bare `pi`.** Arrow keys through the aliases with their live status, `Enter` starts,
  `d` starts and saves it as the default (last pick is preselected next time).
- **A persistent default model.** `pi use flash`, with a fallback to "first reachable endpoint".
- **Live endpoint status.** `pi help` and `pi models` call each endpoint's `/v1/models` with its API key in parallel,
  and show which models are usable right now (`ok`, `bad key`, `down`, `key not set`).
- **A HUD footer.** A two-line status line in the style of claude-hud (details below).
- **Guardrails.** `extensions/git-guard.ts` blocks commits that break the message rules and asks for approval
  before any push. See [Git guard](#git-guard).
- **Package resources that survive `-ne`.** The superpowers skills and the subagent tools are loaded explicitly,
  so extension discovery can stay off and the system prompt stays small.
- **A working thinking config** for chat-template reasoning models (GLM, DeepSeek). Most of the traps here fail
  silently. See [Thinking configuration](#thinking-configuration).
- **A reproducible setup.** pi is pinned in `package.json` and installed locally, so nothing is installed globally.
  Endpoints and keys are kept out of git.

```
pi harness — <harness-root>

Models (* = default):
    pi ds      onprem-prod/<deepseek-model-id>          ok
  * pi flash   onprem-test/<glm-flash-model-id>         ok
    pi glm     onprem-test/<glm-model-id>               401 bad key
```

## Requirements

- Node.js >= 22, npm, git, curl
- zsh (for the shell helpers; `run_pi.sh` itself is plain bash)
- One or more OpenAI-compatible endpoints plus their API keys

## Setup

```bash
git clone <this repo> pi && cd pi
npm install

# 1. Provider catalog: fill in hosts, model ids AND context windows.
#    The template has no "contextWindow" on purpose: a number copied from another
#    model is wrong invisibly, and pi silently assumes 128000 when the key is
#    missing. Ask the endpoint, once per model (vLLM says max_model_len, the
#    nvidia/dynamo stack says context_window):
#      curl -sk -H "Authorization: Bearer $KEY" <baseUrl>/models \
#        | grep -oE '"(max_model_len|context_window)":[0-9]+'
cp config/models.json.example config/models.json
chmod 600 config/models.json
mkdir -p ~/.pi/agent
ln -sfn "$PWD/config/models.json" ~/.pi/agent/models.json

# 2. Aliases: one line per model, "alias|provider/model-id|probe url|API key env var".
cp config/aliases.example config/aliases
```

Then add this to `~/.zshrc`:

```zsh
export ONPREM_PROD_API_KEY="..."
export ONPREM_TEST_API_KEY="..."
source <harness-root>/shell/pi.zsh
```

The env var names are yours to choose. They only have to match the `apiKey` fields in `config/models.json`
(`"$ONPREM_PROD_API_KEY"`) and the last column of `config/aliases`.

Check the setup:

```zsh
source ~/.zshrc
pi help          # every model should show "ok"
pi flash -p "say ok"
```

Optional `~/.pi/agent/settings.json`:

```json
{
  "theme": "dark",
  "defaultThinkingLevel": "high",
  "enableInstallTelemetry": false,
  "packages": ["superpowers-manager/installed", "npm:pi-subagents-j0k3r"]
}
```

`packages` are pi packages installed with `pi install` (`pi install npm:pi-subagents-j0k3r`; `pi list` and
`pi update --extensions` manage them). The launcher loads their extensions by path — see
[What lives outside the repo](#what-lives-outside-the-repo). Without them the session still starts, just without the
skills and the subagent tools.

One more catalog field worth knowing: **vision is per-model opt-in**. `"input": ["text", "image"]` is what lets pi
send image content at all — leave it off and `read` answers a png with "the image will be omitted" instead of the
picture, even though the endpoint would have accepted it.

## Usage

| Command | What it does |
|---|---|
| `pi` | Pick a model with `↑`/`↓` (`j`/`k`, `1`-`9`), `Enter` starts it, `d` also makes it the default, `q`/`Esc` cancels. Non-interactive shells skip the picker and use the default model |
| `pi pick [pi args]` | Force the picker (also when `PI_MODEL` is set) |
| `pi <alias> [pi args]` | Start with a given model; the remaining args are passed to pi |
| `pi <alias> -p "..."` | Run a single prompt, print the answer and exit |
| `pi <alias> --thinking <off\|low\|high\|max>` | Set the thinking level (limited to what the model supports) |
| `pi use <alias>` / `pi use --clear` | Set or clear the persistent default model |
| `pi models` | List models with the default (`*`) and each endpoint's status |
| `pi help` | Usage, plus the models that are available right now |
| `pi config` | Open `config/models.json` in `$EDITOR` |
| `pi raw [args]` | Run the pi binary directly, without the launcher |
| `PI_MODEL=<alias> pi` | Pick a model for one run through an env var |
| `PI_NO_PICKER=1 pi` | Start the default model without the picker |
| `PI_NO_HUD=1 pi` | Start without the HUD footer |
| `pi <alias> +ext <path>` | Load an extra extension |
| `pi <alias> +all` | Turn pi's normal extension discovery back on |

Inside a session: `/model` switches model, `/hud` toggles the HUD, `/help` lists pi's own commands.

`shell/pi.zsh` also registers zsh completion, so `pi <TAB>` offers the subcommands and the aliases from
`config/aliases` (`pi use <TAB>` offers those plus `--clear`).

The launcher picks the model in this order:

1. the alias argument
2. `$PI_MODEL`
3. `config/default-model`
4. the first entry in `config/aliases` whose probe URL answers

## The model picker

Bare `pi` in an interactive shell resolves nothing itself — it opens a picker first:

```
pick a model   ↑/↓ or j/k · 1-3 · Enter start · d start + set as default · q cancel

  prod:
❯ * ds      onprem-prod/<deepseek-model-id>           ok
  test:
    flash   onprem-test/<glm-flash-model-id>          ok
    glm     onprem-test/<glm-model-id>                401 bad key
```

| Key | Action |
|---|---|
| `↑` / `↓`, `k` / `j` | Move the cursor (wraps at both ends) |
| `1`-`9` | Jump to that row |
| `Enter` | Start pi with the selected model |
| `d` | Start it **and** save it as the default (same file as `pi use`) |
| `q`, `Esc` | Cancel — pi does not start, exit status `130` |

It opens only when all three hold: stdin is a terminal (`[ -t 0 ]`), `$PI_MODEL` is empty and `$PI_NO_PICKER` is
unset. Any argument bypasses it as well — `pi flash` uses the alias, and `pi --thinking max` falls through to the
launcher's resolution order above. `pi pick [args]` forces the picker even when `$PI_MODEL` is set (extra args go
to pi), and `PI_NO_PICKER=1 pi` turns it off — which is what scripts and pipes get anyway.

What it does:

- Rows are `config/aliases` in file order, grouped by environment, which is derived from the **probe URL**:
  `*.test-*` or `*-test.*` is `test` (that includes the `…-ai-platform-test.apps.<cluster>` route style),
  everything else is `prod`.
- Statuses are probed in parallel while `fetching model status...` is on screen — `curl -sk -m 2` per row in the
  picker (`pi models` / `pi help` use the 5 s default of the same helper). The menu draws after at most ~6 s and
  rows that never answered show `?`.

  | Status | Meaning |
  |---|---|
  | `ok` | `/v1/models` answered `200` |
  | `401 bad key` / `403 no access` | the key was rejected / is not authorized for that endpoint |
  | `$VAR not set` | the API key env var in the last column of `config/aliases` is not exported |
  | `down` | no answer at all (`curl` code `000`) — host or route unreachable |
  | `?` | the probe did not finish in time |

- The default from `config/default-model` is marked `*`, and the cursor starts on the last pick
  (`config/last-model`), falling back to the default — so `Enter` twice in a row launches the same model.
- A broken row is drawn dim with a red status, but it stays selectable: the probe is information, not a gate.
  `Enter` on a `down` model starts pi against it anyway.
- `Enter` writes `config/last-model`; `d` writes `config/default-model` too and prints `default model: <alias>`.
  Both files are the ones `pi use` writes and the launcher reads.
- The pick is handed to `run_pi.sh` as `provider/model-id`, so it wins over `$PI_MODEL`, `config/default-model` and
  the "first reachable" fallback — the picker is the top of the resolution order, not a replacement for it.
- The menu is drawn on `/dev/tty` (stdout when that is not writable) and wiped after the choice, so the shell
  prompt lands where it started.

## Git guard

`extensions/git-guard.ts` ports the global commit/push rules into a `tool_call` hook, so they hold for every `bash`
call the agent makes — it cannot commit or push its way around them.

**Commits are denied.** Every `git commit` in the command is inspected for its message, in all the shapes an agent
writes them: heredocs, `-m "..."`, `-m '...'`, `--message=...`. (Text *inside* a heredoc body is stripped first, so
a `git commit` that only appears in documentation is not mistaken for a real one.) A commit is rejected when the
message

- carries attribution — `Co-Authored-By`, `Generated with`, `Claude Code`, 🤖,
- spans more than one line, or
- lacks a conventional prefix: `feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert`, optional `(scope)`,
then `: ` and a subject.

The refusal goes back to the model with the exact violation and the required format, so it retries with a valid
message instead of silently dropping the commit.

**Pushes need a human.** `git push` is found through quoted commands and `&&`/`||`/`;`/`|` chains, past git's global
options (`-C`, `-c`, `--git-dir`, …) and through the `git-push` binary form. In an interactive session the agent
gets a Yes/No prompt naming the risky parts — `-f`/`--force`, `--force-with-lease`, `--mirror`, `-d`/`--delete`,
`--prune`, `--all`, `--tags`, `--follow-tags` — and protected targets (`main`, `master`, `develop`, `prod`,
`production`, `release`). Without a UI the push is blocked outright with instructions to ask the user instead.

`PI_ALLOW_GIT_PUSH=1 pi ...` disables the push guard for one session (the commit rules always apply).

## Pasting images (macOS + VS Code terminal)

pi reads the clipboard on `ctrl+v` (`app.clipboard.pasteImage`; `alt+v` on Windows/WSL — see
`dist/core/keybindings.js`). That works in a plain terminal, but not inside VS Code's integrated one, where
`cmd+v` is `workbench.action.terminal.paste`: VS Code handles the key itself (it sits in `commandsToSkipShell`),
so the TUI never sees it — and that paste only sends clipboard **text**, or the path of a file copied in Finder
(`readText()`, and when that is empty `readResources()` → `fsPath`). A screenshot held in the clipboard as an
image has neither, so nothing reaches the app.

Claude Code works the same way. Its binary (`claude-darwin-arm64/claude`) binds `chat:imagePaste` to `ctrl+v`,
ships the tip *"Paste images into Claude Code using control+v (not cmd+v!)"* and lists `cmd+v` as un-rebindable
with the reason "macOS system paste". The difference is one thing: it converts a pasted **path** ending in
`.png/.jpg/.jpeg/.gif/.webp` into an image attachment. pi keeps the path as text and lets the agent `read` it —
the `read` tool sends the file as an image part when the model declares `image` input.

To make `cmd+v` behave like `ctrl+v` in VS Code, remap it: the terminal then receives byte `0x16` and pi pastes
the image itself (screenshots included).

```jsonc
// ~/Library/Application Support/Code/User/keybindings.json
{ "key": "cmd+v", "command": "workbench.action.terminal.sendSequence",
  "args": { "text": "\u0016" }, "when": "terminalFocus" },
{ "key": "cmd+shift+v", "command": "workbench.action.terminal.paste", "when": "terminalFocus" }
```

- `when: terminalFocus` keeps `cmd+v` normal everywhere else in the editor (and in other windows).
- `cmd+shift+v` is unbound for the terminal on macOS (`primary:2100` is `cmd+v`; `3124` is only the
  Windows/Linux variant), so the fallback shadows nothing. It restores VS Code's own paste for plain shells,
  where the new `cmd+v` sends `^V` (readline quoted-insert) and pastes nothing.
- iTerm2 equivalent: Settings → Keys → Key Bindings → `⌘V` → **Send Hex Code** `0x16`.
- A pi-side binding (`{"app.clipboard.pasteImage": ["ctrl+v", "super+v"]}` in `~/.pi/agent/keybindings.json`)
  does **not** help here: `super` is only reported over the Kitty keyboard protocol, and by then the key has
  already been consumed.

The paste writes `$TMPDIR/pi-clipboard-<uuid>.png` and inserts the **path** — the keystroke does not attach the
image to the message. The model reads it with the `read` tool, so vision requires `"input": ["text", "image"]`
for that model in `config/models.json`.

That keybinding file is machine-local and not part of this repo, so back it up before editing and keep the copy
for the day the remap gets in the way: `cp keybindings.json keybindings.json.bak` / `cp keybindings.json.bak
keybindings.json`.

## HUD footer

`wrappers/hud.ts` replaces pi's footer with two lines:

```
[my-model · high] ████░░░░░░ 38% 100k/262k │ onprem-test │ ⎇ main* │ ~/code/app
◐ bash: npm test │ ✓ read ×4  edit ×2 │ ✗ 1 │ ↑120k ↓8.1k │ ⏱ 4m12s │ turn 6
```

- **Line 1:** model and thinking level, the context-window bar, the provider, the git branch (`*` means uncommitted
  changes), and the working directory.
- **Line 2:** the tool that is currently running with its argument, per-tool completion counts, the error count,
  session tokens in and out, elapsed time and turn count. Status text set by other extensions is appended at the end.

The colors are fixed truecolor values in the `PALETTE` object at the top of the file, so they don't change with
the pi theme. The context bar changes shade at 65% and at 85%. The file is a plain pi extension, so you can also
use it without this harness: `pi -e path/to/hud.ts`.

## Thinking configuration

`config/models.json.example` contains settings that we got working on chat-template servers. We learned the
following by trial and error:

- **`compat.supportsReasoningEffort` must be `true`.** If it is `false`, pi drops thinking entirely, even though the
  effort is actually sent through `chat_template_kwargs`.
- **The thinking-toggle kwarg depends on the model family.** DeepSeek uses `thinking`, while GLM uses
  `enable_thinking`. If you send the wrong one, the server still answers `200` and keeps thinking on, so the HTTP
  status won't tell you anything.
- **Servers don't validate `reasoning_effort`.** Take `thinkingLevelMap` from the model card and set the levels the
  model doesn't support to `null`, which hides them in pi.
- **Test thinking with a real problem.** A prompt like "say ok" makes reasoning models skip thinking even at
  `high`. Compare the length of the thinking block between levels instead:
  `pi <alias> --thinking high -p 'prove the sum of the first n odd numbers is n^2'`
- **Get the served model id from `GET /v1/models`.** It can differ from the deployment name, and a wrong id shows
  up as a 404, not as a connection error.

## Layout

```
.
├── run_pi.sh                  launcher: resolves the model, loads extensions, starts pi
├── shell/pi.zsh               zsh function `pi` (picker, help, models, use, pick, config, raw) plus completion
├── wrappers/hud.ts            HUD footer extension
├── extensions/
│   └── git-guard.ts           commit rules + push approval as a `tool_call` hook
├── config/
│   ├── models.json.example    provider catalog template        → models.json   (gitignored)
│   ├── aliases.example        alias / probe / key-var template  → aliases       (gitignored)
│   ├── default-model          written by `pi use`, and by `d` in the picker     (gitignored)
│   └── last-model             written by the picker, preselected next time      (gitignored)
└── package.json               pins the pi version
```

The launcher always runs pi with `-ne` (extension discovery off) and loads a fixed set instead — fewer extensions
means a smaller system prompt:

| Extension | What it adds |
|---|---|
| `extensions/git-guard.ts` | commit-message rules and push approval ([Git guard](#git-guard)) |
| `~/.pi/agent/superpowers-manager/installed/.pi/extensions/superpowers.ts` | the superpowers skills, and the `using-superpowers` bootstrap that is injected at session start and after every compaction |
| `~/.pi/agent/npm/node_modules/pi-subagents-j0k3r/index.ts` | the `subagent_*` tools and the subagents-configuration skill |
| `wrappers/hud.ts` | the HUD footer (skipped with `PI_NO_HUD=1`) |

The two `~/.pi/agent` rows are named explicitly *because* discovery is off: `-ne` also skips the extension and
skill paths declared by the `packages` in `~/.pi/agent/settings.json`, so the launcher points pi at their entry
points itself. Both are optional — a missing path is skipped (`[ -e ... ] && add_ext`) and the session just runs
with the harness extensions only.

`+ext <path>` adds one more extension; `+all` drops the fixed set and turns normal discovery back on.

## What lives outside the repo

The harness owns everything under `config/`; the rest of what pi needs sits in `~/.pi/agent`:

| Path | Written by | Role |
|---|---|---|
| `models.json` | the symlink from [Setup](#setup) | the provider catalog, shared with pi; the aliases in `config/aliases` must resolve against it |
| `settings.json` | you | theme, `defaultThinkingLevel`, and `packages` — the two package ids whose extensions the launcher loads by path |
| `superpowers-manager/installed/` | the superpowers installer | the `superpowers` package: its skills plus the pi extension entry point |
| `npm/` | `pi install` | pi's own npm root, here `pi-subagents-j0k3r` (dependency declared in `npm/package.json`) |
| `agents/*.md` (or `<project>/.pi/agents/*.md`) | you | markdown subagent definitions, e.g. `test-engineer.md`; project definitions win over global ones |
| `subagents.json` / `.pi/subagents.json` | you | subagent defaults; the project file overrides the global one field by field |
| `sessions/`, `crashes.json`, `bin/` | pi | transcripts (one JSONL per session), crash reports, and the managed `fd`/`rg` downloads |

`pi config` only opens `config/models.json` — the paths above belong to pi, so change them through pi
(`/settings`, `pi install`, `pi list`) or by hand.

## Context compaction

Nothing in this harness drives compaction any more. It used to symlink pi's bundled
`examples/extensions/trigger-compact.ts`, which forced a compaction on every turn that crossed **100k tokens** —
fine for a small-context model, but it threw away most of the window on the 262k/524k models and paid for a
summarization call each time.

Compaction is now whatever pi does on its own: `contextTokens > contextWindow - reserveTokens`, with pi's built-in
`reserveTokens: 16384` and `keepRecentTokens: 20000` (see `dist/core/settings-manager.js`). Nothing in
`~/.pi/agent/settings.json` overrides it, so the effective trigger is:

| Context window | Compaction fires at |
|---|---|
| 262.144 | 245.760 tokens (~94% full) |
| 524.288 | 507.904 tokens (~97% full) |

To compact earlier, add a `compaction` block to `~/.pi/agent/settings.json`. `reserveTokens` is absolute, not a
percentage — hold back a tenth of the window to fire near 90%:

```json
"compaction": {
  "reserveTokens": 26214,
  "modelOverrides": { "<provider>/<model id>": { "reserveTokens": 52428 } }
}
```

That file lives in `~/.pi/agent/`, not in this repo, so a fresh clone on another machine starts from pi's defaults.

### `contextWindow` must come from the endpoint, not from memory

The compaction threshold, the HUD percentage and the overflow check all read `contextWindow` from
`config/models.json`, and pi never verifies it — a wrong value is silently accepted (an absent one falls back to
128000). Ask the endpoint instead; the field name depends on the serving stack:

```bash
base=$(python3 -c "import json;c=json.load(open('config/models.json'))['providers']['<provider>'];print((c['models'][0].get('baseUrl') or c['baseUrl']).rstrip('/'))")
curl -sk -H "Authorization: Bearer $<PROVIDER_KEY_VAR>" "$base/models" | python3 -m json.tool | grep -E 'context_window|max_model_len'
```

- vLLM reports `max_model_len`; the nvidia/dynamo stack reports `context_window`.
- A provider key can front several deployments — each model's own `baseUrl` wins over the provider's, so read
  `/v1/models` **per model**, not once per provider.
- Both fields describe prompt **plus** generation; `reserveTokens` is what keeps the answer inside that budget.

## Security notes

- Only the `*.example` files are tracked. `config/models.json` and `config/aliases` contain real hosts, and they
  stay local.
- API keys come from environment variables (`"apiKey": "$VAR"` in `models.json`) and are never written to files in
  the repo.
- Extensions run with full access to your system. Review any extension before you load it with `+ext` — this
  includes the two package extensions the launcher loads by path (see [Layout](#layout)), since they are code that
  runs in every session.
- If you move the repo, point the `~/.pi/agent/models.json` symlink and your `source` line at the new path.
