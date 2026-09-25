/**
 * HUD footer — claude-hud style status line for pi.
 *
 *   [my-model · high] ████░░░░░░ 38% 99k/262k │ onprem-test │ ⎇ main* │ ~/code/app
 *   ◐ bash: npm test │ ✓ read ×4  edit ×2 │ ✗ 1 │ ↑120k ↓8k │ ⏱ 4m12s │ turn 6
 *
 * /hud toggles back to pi's built-in footer.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { homedir } from "node:os";

type Running = { name: string; detail: string };

// Red palette (truecolor), independent of the pi theme. Tweak here.
const PALETTE = {
	model: "#ff4d5e", // [model · level]
	level: "#ffb3c1",
	barLow: "#ff8fa3", // context < 65%
	barMid: "#ff4d5e", // context < 85%
	barHigh: "#ff0033", // context >= 85%
	barEmpty: "#4a2a30",
	provider: "#e07a8a",
	branch: "#ff6b81",
	dirty: "#ffd166",
	cwd: "#a8707a",
	running: "#ff4d5e",
	tool: "#ffb3c1",
	ok: "#ff8fa3",
	count: "#c98b95",
	error: "#ff0033",
	dim: "#7a5057",
};
const hex = (h: string) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16)).join(";");
const paint = (color: keyof typeof PALETTE, text: string) => `\x1b[38;2;${hex(PALETTE[color])}m${text}\x1b[39m`;

const fmtTokens = (n: number) =>
	n < 1000 ? `${n}` : n < 1_000_000 ? `${(n / 1000).toFixed(n < 10_000 ? 1 : 0)}k` : `${(n / 1_000_000).toFixed(1)}M`;

const fmtDuration = (ms: number) => {
	const s = Math.floor(ms / 1000);
	if (s < 60) return `${s}s`;
	const m = Math.floor(s / 60);
	if (m < 60) return `${m}m${String(s % 60).padStart(2, "0")}s`;
	return `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}m`;
};

const toolDetail = (name: string, args: any): string => {
	if (!args || typeof args !== "object") return "";
	const raw = args.command ?? args.path ?? args.file_path ?? args.pattern ?? args.url ?? "";
	return String(raw).replace(/\s+/g, " ").slice(0, 40);
};

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let ctx: ExtensionContext | undefined;
	let requestRender = () => {};
	let startedAt = Date.now();
	let turns = 0;
	let errors = 0;
	let dirty = false;
	const running = new Map<string, Running>();
	const done = new Map<string, number>();

	const refreshGit = async () => {
		try {
			const r = await pi.exec("git", ["status", "--porcelain", "--untracked-files=no"], { timeout: 2000 });
			dirty = r.code === 0 && r.stdout.trim().length > 0;
		} catch {
			dirty = false;
		}
		requestRender();
	};

	const install = (c: ExtensionContext) => {
		if (!c.hasUI) return;
		c.ui.setFooter((tui, _theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsub = footerData.onBranchChange(() => void refreshGit());
			const sep = paint("dim", " │ ");

			return {
				dispose() {
					unsub();
					requestRender = () => {};
				},
				invalidate() {},
				render(width: number): string[] {
					const c = ctx;
					const model = c?.model;

					// line 1: model · thinking │ context bar │ provider │ git │ cwd
					const level = pi.getThinkingLevel();
					const head =
						paint("model", `[${model?.id ?? "no-model"}`) +
						paint("dim", " · ") +
						paint("level", level) +
						paint("model", "]");

					let ctxPart = paint("dim", "ctx ?");
					const usage = c?.getContextUsage();
					if (usage) {
						const pct = usage.percent ?? 0;
						const cells = 10;
						const filled = Math.min(cells, Math.round((pct / 100) * cells));
						const color = pct >= 85 ? "barHigh" : pct >= 65 ? "barMid" : "barLow";
						const bar = paint(color, "█".repeat(filled)) + paint("barEmpty", "░".repeat(cells - filled));
						const nums =
							usage.tokens == null
								? `?/${fmtTokens(usage.contextWindow)}`
								: `${fmtTokens(usage.tokens)}/${fmtTokens(usage.contextWindow)}`;
						ctxPart = `${bar} ${paint(color, `${Math.round(pct)}%`)} ${paint("dim", nums)}`;
					}

					const parts1 = [head + " " + ctxPart];
					if (model?.provider) parts1.push(paint("provider", model.provider));
					const branch = footerData.getGitBranch();
					if (branch) parts1.push(paint("branch", `⎇ ${branch}`) + (dirty ? paint("dirty", "*") : ""));
					const cwd = (c?.cwd ?? process.cwd()).replace(homedir(), "~");
					parts1.push(paint("cwd", cwd));

					// line 2: running tool │ tool counts │ errors │ tokens │ duration │ turns │ other statuses
					const parts2: string[] = [];
					for (const r of running.values()) {
						parts2.push(paint("running", "◐ ") + paint("tool", r.name) + (r.detail ? paint("dim", `: ${r.detail}`) : ""));
					}
					if (done.size) {
						const top = [...done.entries()].sort((a, b) => b[1] - a[1]).slice(0, 5);
						parts2.push(paint("ok", "✓ ") + top.map(([n, k]) => paint("count", `${n} ×${k}`)).join("  "));
					}
					if (errors) parts2.push(paint("error", `✗ ${errors}`));

					let input = 0;
					let output = 0;
					for (const e of c?.sessionManager.getBranch() ?? []) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage?.input ?? 0;
							output += m.usage?.output ?? 0;
						}
					}
					parts2.push(paint("dim", `↑${fmtTokens(input)} ↓${fmtTokens(output)}`));
					parts2.push(paint("dim", `⏱ ${fmtDuration(Date.now() - startedAt)}`));
					if (turns) parts2.push(paint("dim", `turn ${turns}`));
					for (const s of footerData.getExtensionStatuses().values()) if (s) parts2.push(s);

					return [truncateToWidth(parts1.join(sep), width), truncateToWidth(parts2.join(sep), width)];
				},
			};
		});
	};

	pi.on("session_start", async (_e, c) => {
		ctx = c;
		startedAt = Date.now();
		turns = errors = 0;
		running.clear();
		done.clear();
		if (enabled) install(c);
		await refreshGit();
	});
	pi.on("model_select", async (_e, c) => {
		ctx = c;
		requestRender();
	});
	pi.on("thinking_level_select", async (_e, c) => {
		ctx = c;
		requestRender();
	});
	pi.on("turn_start", async (_e, c) => {
		ctx = c;
		turns++;
		requestRender();
	});
	pi.on("tool_execution_start", async (e, c) => {
		ctx = c;
		running.set(e.toolCallId, { name: e.toolName, detail: toolDetail(e.toolName, e.args) });
		requestRender();
	});
	pi.on("tool_execution_end", async (e, c) => {
		ctx = c;
		running.delete(e.toolCallId);
		if (e.isError) errors++;
		else done.set(e.toolName, (done.get(e.toolName) ?? 0) + 1);
		requestRender();
	});
	pi.on("message_end", async (_e, c) => {
		ctx = c;
		requestRender();
	});
	pi.on("agent_end", async (_e, c) => {
		ctx = c;
		running.clear();
		await refreshGit();
	});

	// keep the ⏱ ticking while idle
	const timer = setInterval(() => requestRender(), 1000);
	timer.unref?.();
	pi.on("session_shutdown", async () => clearInterval(timer));

	pi.registerCommand("hud", {
		description: "Toggle HUD footer",
		handler: async (_args, c) => {
			enabled = !enabled;
			ctx = c;
			if (enabled) install(c);
			else c.ui.setFooter(undefined);
			c.ui.notify(enabled ? "HUD enabled" : "Default footer restored", "info");
		},
	});
}
