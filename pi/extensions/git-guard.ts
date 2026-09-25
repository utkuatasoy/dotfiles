/**
 * Git Guard — port of ~/.claude/hooks/commit-guard.py + push-guard.py
 *
 * commit rules (auto-deny, mirroring ~/.claude/skills/commit.md):
 *   - no co-author attribution (Co-Authored-By)
 *   - no "Generated with" / "Claude Code" / robot emoji
 *   - single-line message only
 *   - conventional-commit type prefix required
 *
 * push rules (interactive: confirm; non-interactive: block):
 *   - every `git push` variant prompts, with risky-flag / protected-branch notes
 *
 * Override push guard for one session:  PI_ALLOW_GIT_PUSH=1
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// ---------------------------------------------------------------- commit ----

const CONV_TYPES = "feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert";

const FORBIDDEN_SUBSTRINGS: Array<[string, string]> = [
	["Co-Authored-By", "co-author attribution not allowed"],
	["Co-authored-by", "co-author attribution not allowed"],
	["Generated with", "'generated with' attribution not allowed"],
	["generated with", "'generated with' attribution not allowed"],
	["Claude Code", "'Claude Code' attribution not allowed"],
	["\u{1F916}", "robot emoji not allowed"],
];

/** Pull out commit message bodies from a git commit command. */
export function extractMessages(cmd: string): string[] {
	const messages: string[] = [];

	// Heredoc form: <<'EOF' ... EOF  or  <<EOF ... EOF
	for (const m of cmd.matchAll(/<<-?\s*'?(\w+)'?\s*\n([\s\S]*?)\n\s*\1\b/g)) {
		messages.push(m[2]);
	}

	// -m "..." (double quoted)
	for (const m of cmd.matchAll(/-m\s+"((?:[^"\\]|\\.)*)"/g)) {
		messages.push(m[1]);
	}

	// -m '...' (single quoted)
	for (const m of cmd.matchAll(/-m\s+'([^']*)'/g)) {
		messages.push(m[1]);
	}

	// --message="..." / --message='...'
	for (const m of cmd.matchAll(/--message=\s*"((?:[^"\\]|\\.)*)"/g)) {
		messages.push(m[1]);
	}
	for (const m of cmd.matchAll(/--message=\s*'([^']*)'/g)) {
		messages.push(m[1]);
	}

	return messages;
}

/** Remove heredoc bodies so `git commit` text *inside* a heredoc is not
 *  misdetected as an actual commit invocation. */
export function stripHeredocBodies(cmd: string): string {
	return cmd.replace(/(<<-?\s*'?\w+'?)\s*\n[\s\S]*?\n\s*\w+\b/g, "$1");
}

/** True if the command invokes `git commit` (not git log, commit-tree, ...). */
export function isGitCommit(cmd: string): boolean {
	const stripped = stripHeredocBodies(cmd);
	const patterns = [
		/\bgit\s+(?:-[^\s]+\s+)*commit\b/,
		/\bgit(?:\s+\S+)*?\s+commit\b/,
	];
	return patterns.some((p) => p.test(stripped));
}

/** All commit-rule violations for the command's message(s), if any. */
export function commitViolations(cmd: string): string[] {
	const violations: string[] = [];

	for (const [needle, reason] of FORBIDDEN_SUBSTRINGS) {
		if (cmd.includes(needle)) violations.push(`${reason} (found '${needle}')`);
	}

	const messages = extractMessages(cmd);

	// multiline body check
	for (const msg of messages) {
		if (msg.trim().includes("\n")) {
			violations.push("multiline commit body not allowed — single-line only");
			break;
		}
	}

	// conventional prefix check (on the first/only message)
	if (messages.length > 0) {
		const firstLine = messages[0].trim().split("\n", 1)[0];
		if (!new RegExp(`^(${CONV_TYPES})(\\([^)]+\\))?!?:\\s+\\S`).test(firstLine)) {
			violations.push(
				`missing conventional-commit prefix (${CONV_TYPES}): got '${firstLine.slice(0, 60)}'`,
			);
		}
	}

	return violations;
}

// ------------------------------------------------------------------ push ----

// git's own global options that consume the following token
const GLOBAL_OPTS_WITH_VALUE = new Set([
	"-C", "-c", "--git-dir", "--work-tree", "--exec-path",
	"--namespace", "--super-prefix", "--config-env",
]);

const PUSH_SUBCOMMANDS = new Set(["push"]);

// flags worth calling out in the prompt
const RISKY_FLAGS: Record<string, string> = {
	"-f": "force push",
	"--force": "force push",
	"--force-with-lease": "force-with-lease push",
	"--force-if-includes": "force-if-includes push",
	"--mirror": "mirror push (overwrites all remote refs)",
	"--delete": "deletes a remote ref",
	"-d": "deletes a remote ref",
	"--prune": "prunes remote refs",
	"--all": "pushes all branches",
	"--tags": "pushes tags",
	"--follow-tags": "pushes tags",
};

const PROTECTED_BRANCHES = new Set(["main", "master", "develop", "prod", "production", "release"]);

const SEPARATORS = /&&|\|\||;|\||\n/;

/** Quote-aware tokenizer (good-enough shlex.split port). */
export function tokenize(segment: string): string[] {
	const tokens: string[] = [];
	let cur = "";
	let quote: string | null = null;
	let has = false;
	for (let i = 0; i < segment.length; i++) {
		const c = segment[i];
		if (quote) {
			if (c === quote) {
				quote = null;
			} else if (c === "\\" && quote === '"' && i + 1 < segment.length) {
				cur += segment[++i];
			} else {
				cur += c;
			}
		} else if (c === '"' || c === "'") {
			quote = c;
			has = true;
		} else if (c === "\\" && i + 1 < segment.length) {
			cur += segment[++i];
			has = true;
		} else if (/\s/.test(c)) {
			if (cur || has) {
				tokens.push(cur);
				cur = "";
				has = false;
			}
		} else {
			cur += c;
		}
	}
	if (cur || has) tokens.push(cur);
	return tokens;
}

function isGit(token: string): boolean {
	const base = token.split("/").pop()!;
	return base === "git" || base === "git.exe";
}

/** Return one token-list per `git push` found in the command. */
export function findPushes(cmd: string): string[][] {
	const found: string[][] = [];
	for (const segment of stripHeredocBodies(cmd).split(SEPARATORS)) {
		const tokens = tokenize(segment);
		let i = 0;
		while (i < tokens.length) {
			const tok = tokens[i];

			// `git-push ...` direct binary form
			const base = tok.split("/").pop()!;
			if (base === "git-push" || base === "git-push.exe") {
				found.push(tokens.slice(i));
				break;
			}

			if (!isGit(tok)) {
				i += 1;
				continue;
			}

			// walk past git's global options to reach the subcommand
			let j = i + 1;
			while (j < tokens.length) {
				const t = tokens[j];
				if (GLOBAL_OPTS_WITH_VALUE.has(t)) {
					j += 2;
					continue;
				}
				if (t.startsWith("-")) {
					j += 1;
					continue;
				}
				break;
			}

			if (j < tokens.length && PUSH_SUBCOMMANDS.has(tokens[j])) {
				found.push(tokens.slice(j));
			}
			i = j > i ? j + 1 : i + 1;
		}
	}
	return found;
}

/** Human-readable one-liner for a single push invocation. */
export function describePush(pushTokens: string[]): string {
	const flags = pushTokens.slice(1).filter((f) => f.startsWith("-"));
	const args = pushTokens.slice(1).filter((a) => !a.startsWith("-"));

	const notes: string[] = [];
	for (const f of flags) {
		const key = f.split("=", 1)[0];
		if (key in RISKY_FLAGS) notes.push(RISKY_FLAGS[key]);
	}

	const target = args.length > 0 ? args.join(" ") : "default remote/branch";
	for (const a of args) {
		if (PROTECTED_BRANCHES.has(a.split(":").pop()!.split("/").pop()!)) {
			notes.push(`targets protected branch '${a}'`);
			break;
		}
	}

	let line = `git ${pushTokens.join(" ")}  ->  ${target}`;
	if (notes.length > 0) {
		line += "\n      ! " + [...new Set(notes)].sort().join("; ");
	}
	return line;
}

// ------------------------------------------------------------------ main ----

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = (event.input?.command as string) ?? "";

		// --- commit rules: always deny, model sees the reason and can retry ---
		if (isGitCommit(command)) {
			const violations = commitViolations(command);
			if (violations.length > 0) {
				return {
					block: true,
					reason:
						"Commit blocked by user's global commit rules:\n" +
						violations.map((v) => `  - ${v}`).join("\n") +
						`\n\nRequired format: \`<type>(scope): <imperative subject>\` — ` +
						`single line, no body, no co-author, no 'generated by', no emoji.\n` +
						`Rewrite the commit command and try again.`,
				};
			}
			return undefined;
		}

		// --- push guard: confirm interactively, block non-interactively ------
		const pushes = findPushes(command);
		if (pushes.length === 0) return undefined;
		if (process.env.PI_ALLOW_GIT_PUSH === "1") return undefined;

		const detail = pushes.map((p) => describePush(p)).join("\n");

		if (ctx.hasUI) {
			const choice = await ctx.ui.select(
				`⚠️ Push requires approval:\n\n  ${detail}\n\nAllow?`,
				["No, block it", "Yes, push"],
			);
			if (choice === "Yes, push") return undefined;
			return { block: true, reason: "Push rejected — requires explicit user approval." };
		}

		return {
			block: true,
			reason:
				"Push requires explicit user approval (global push rule):\n" +
				pushes.map((p) => `  - ${describePush(p)}`).join("\n") +
				"\n\nDo not push; ask the user to run it or set PI_ALLOW_GIT_PUSH=1.",
		};
	});
}

// export internals for unit tests
export const __test = { stripHeredocBodies, isGitCommit, extractMessages, commitViolations, tokenize, findPushes, describePush };
