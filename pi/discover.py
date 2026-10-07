#!/usr/bin/env python3
"""pi discover — keep config/aliases and config/models.json in sync with a model registry.

For each environment in config/discover.json it fetches the model registry and adds every
model that pi can actually run (vLLM + chat/text-to-text) as a runnable alias + provider
entry. Models it added before that left the registry are dropped again. Hand-authored
aliases and model entries are never touched — only the entries discover itself created
(tracked in config/discovered-models.json) are reconciled.

Token: read from $REGISTRY_TOKEN or config/registry-token (write it with `pi token <JWT>`).
"""
from __future__ import annotations

import json
import os
import re
import ssl
import sys
import urllib.error
import urllib.request

HARNESS = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(HARNESS, "config")
TOKEN_FILE = os.path.join(CONFIG, "registry-token")
ENVS_FILE = os.path.join(CONFIG, "discover.json")
MANIFEST_FILE = os.path.join(CONFIG, "discovered-models.json")
ALIASES_FILE = os.path.join(CONFIG, "aliases")
MODELS_FILE = os.path.join(CONFIG, "models.json")



def load_envs() -> list[tuple[str, str, str, str, str]]:
    """config/discover.json -> [(env, registry url, gateway base url, provider, api-key env var)]."""
    if not os.path.exists(ENVS_FILE):
        return []
    with open(ENVS_FILE, encoding="utf-8") as f:
        data = json.load(f)
    return [(e["env"], e["registry"], e["gateway"].rstrip("/"), e["provider"], e["keyvar"])
            for e in data.get("envs") or []]


ENVS = load_envs()

# Model families for display grouping; first prefix match wins (case-insensitive,
# after stripping ci-/llm- prefixes).
FAMILIES = [
    "deepseek", "glm", "qwen", "gemma", "llama", "minimax", "mimo", "gpt-oss",
    "kimi", "step", "rune", "ornith", "muse", "diffusion", "dots", "bge", "e5",
    "snowflake", "whisper", "parakeet", "fastpitch", "sortformer", "stt", "nemotron",
    "turkish-gemma", "translategemma",
]
DEFAULT_FAMILY = "other"

# Names that are not usable as a coding-agent chat model even when served by vLLM.
EXCLUDE_NAME = re.compile(
    r"(embedding|bge|rerank|e5|snowflake|asr|stt|speech|whisper|tts|ttv|audio|parakeet|"
    r"fastpitch|sortformer|nemotron|ctc|ocr)"
)

DEFAULT_CONTEXT = 128000
MAX_OUTPUT_TOKENS = 65536


def max_tokens_for(context: int) -> int:
    """Output budget: a quarter of the window, so the prompt still fits (vLLM rejects
    prompt + max_tokens > max_model_len)."""
    return min(context // 4, MAX_OUTPUT_TOKENS)

# Internal CA certs — match the harness' curl -sk behaviour.
CTX = ssl._create_unverified_context()


def _http(url: str, api_key: str, *, method: str = "GET", body=None, timeout: float = 15.0):
    """urllib call with an Authorization bearer; returns (status, data|None)."""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
        "User-Agent": "pi-discover",
    }
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=CTX) as r:
            raw = r.read()
            try:
                return r.status, json.loads(raw)
            except (json.JSONDecodeError, ValueError):
                return r.status, None
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            return e.code, None
    except Exception:  # noqa: BLE001 — timeout / connection / SSL
        return None, None


def fetch_served(base_url: str, api_key: str) -> dict[str, int | None]:
    """GET {base}/models -> {served id: max_model_len or None} for this key, or {} on any failure.

    vLLM reports the real max_model_len here; the registry value can be stale.
    """
    status, data = _http(f"{base_url}/models", api_key, timeout=8)
    if status != 200 or not isinstance(data, dict):
        return {}
    served = {}
    for m in data.get("data", []):
        if not m.get("id"):
            continue
        try:
            served[m["id"]] = int(m["max_model_len"]) if m.get("max_model_len") else None
        except (TypeError, ValueError):
            served[m["id"]] = None
    return served


def verify_chat(base_url: str, api_key: str, model_id: str) -> bool:
    """POST {base}/chat/completions with max_tokens=1; True when a response returns."""
    status, _ = _http(
        f"{base_url}/chat/completions", api_key, method="POST",
        body={"model": model_id, "messages": [{"role": "user", "content": "hi"}],
              "max_tokens": 1},
        timeout=35,
    )
    return status == 200


def verify_candidate(item) -> tuple[str, str, str | None, int | None]:
    """Returns (env, model_name, working_model_id, served_context) or (env, name, None, None).

    A candidate is usable when a 1-token chat completion returns a response. We try
    the registry name first, then the served ids that are related to it (a deployment
    can serve the model under a different id, e.g. team__deepseek-v41-flash).
    """
    env, name, info = item
    key = os.environ.get(info["keyvar"], "")
    if not key:
        return env, name, None, None
    base = info["baseUrl"]
    norm = re.sub(r"[^a-z0-9]+", "", name.lower())
    candidates = [name]
    served = fetch_served(base, key)
    if norm:
        for sid in served:
            sn = re.sub(r"[^a-z0-9]+", "", sid.lower())
            if norm == sn or (norm and (norm in sn or sn in norm)):
                candidates.append(sid)
    seen = set()
    for cid in candidates:
        if cid in seen:
            continue
        seen.add(cid)
        if verify_chat(base, key, cid):
            ctx = served.get(cid)
            if ctx is None and len(served) == 1:
                ctx = next(iter(served.values()))
            return env, name, cid, ctx
    return env, name, None, None


def family_of(model_name: str) -> str:
    n = model_name.lower()
    n = re.sub(r"^(ci-|llm-|ci_)", "", n)
    for fam in FAMILIES:
        if n.startswith(fam):
            return fam
    m = re.match(r"[a-z0-9]+", n)
    return m.group(0) if m else DEFAULT_FAMILY


def is_runnable(model: dict) -> bool:
    """True when pi could actually run this model: vLLM + chat-capable."""
    if model.get("runtime") != "vllm" or not model.get("is_active", True):
        return False
    labels = [str(x).lower() for x in (model.get("details") or {}).get("labels") or []]
    if "chat" in labels or "text-to-text" in labels:
        return True
    return not EXCLUDE_NAME.search(model.get("model_name", "").lower())


def context_window(model: dict) -> int:
    opts = (model.get("args") or {}).get("options") or {}
    raw = opts.get("max-model-len") or opts.get("max_model_len")
    try:
        return int(raw) if raw is not None else DEFAULT_CONTEXT
    except (TypeError, ValueError):
        return DEFAULT_CONTEXT


def has_vision(model: dict) -> bool:
    labels = [str(x).lower() for x in (model.get("details") or {}).get("labels") or []]
    return any(t in labels for t in ("image-to-text", "vision", "multimodal"))


def slugify(name: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9_-]+", "-", name)
    return re.sub(r"-{2,}", "-", s).strip("-")


def env_of_url(url: str) -> str:
    return "test" if (".test-" in url or "-test." in url) else "prod"


def fetch_registry(env: str, url: str, token: str) -> list[dict]:
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "User-Agent": "pi-discover",
    })
    # Internal CA certs — match the harness' curl -sk behaviour.
    ctx = ssl._create_unverified_context()
    try:
        with urllib.request.urlopen(req, timeout=30, context=ctx) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 401:
            sys.exit(f"discover: token invalid/expired for {env} — run: pi token <JWT>")
        sys.exit(f"discover: HTTP {e.code} from {env} registry")
    except Exception as e:  # noqa: BLE001
        sys.exit(f"discover: failed to reach {env} registry: {e}")


def read_aliases() -> tuple[list[dict], list[str]]:
    """Parse config/aliases. Returns (parsed non-comment rows, raw comment+blank lines).

    A row: {"alias", "spec" (provider/id), "url", "keyvar", "env"}.
    """
    if not os.path.exists(ALIASES_FILE):
        return [], []
    rows, skeleton = [], []
    with open(ALIASES_FILE, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                skeleton.append(line)
                continue
            parts = [p.strip() for p in raw.split("|")]
            if len(parts) < 4:
                skeleton.append(line)
                continue
            alias, spec, url, keyvar = parts[0], parts[1], parts[2], parts[3]
            rows.append({
                "alias": alias, "spec": spec, "url": url, "keyvar": keyvar,
                "env": env_of_url(url),
            })
    return rows, skeleton


def read_models() -> dict:
    if not os.path.exists(MODELS_FILE):
        return {"providers": {}}
    with open(MODELS_FILE, encoding="utf-8") as f:
        return json.load(f)


def write_aliases(rows: list[dict], skeleton: list[str]) -> None:
    lines = list(skeleton)
    for r in rows:
        lines.append(f"{r['alias']}|{r['spec']}|{r['url']}|{r['keyvar']}")
    with open(ALIASES_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def write_models(data: dict) -> None:
    with open(MODELS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.write("\n")


def provider_for_env(env: str) -> str:
    for e, _, _, p, _ in ENVS:
        if e == env:
            return p
    raise KeyError(env)


def main() -> None:
    if not ENVS:
        sys.exit(f"discover: no environments — copy {ENVS_FILE}.example to {ENVS_FILE} and fill it in")
    token = os.environ.get("REGISTRY_TOKEN", "").strip()
    if not token and os.path.exists(TOKEN_FILE):
        token = open(TOKEN_FILE, encoding="utf-8").read().strip()
    if not token:
        sys.exit("discover: no token — run: pi token <JWT>  (or export REGISTRY_TOKEN)")

    # 1. Fetch registries and compute the desired runnable set per env.
    desired: dict[str, dict[str, dict]] = {e: {} for e, *_ in ENVS}
    for env, registry_url, gateway, provider, keyvar in ENVS:
        for m in fetch_registry(env, registry_url, token):
            if not is_runnable(m):
                continue
            name = m["model_name"]
            base = f"{gateway}/{name}/v1"
            desired[env][name] = {
                "id": name,
                "env": env,
                "provider": provider,
                "keyvar": keyvar,
                "url": f"{base}/models",   # probe URL (alias)
                "baseUrl": base,           # models.json baseUrl
                "context": context_window(m),
                "vision": has_vision(m),
                "family": family_of(name),
            }

    # 2. Verify every candidate with a real 1-token chat completion (parallel).
    #    Only models that actually return a response are kept — a /v1/models 200
    #    alone is not enough (shared/broken routes still answer the probe).
    from concurrent.futures import ThreadPoolExecutor, as_completed
    print("discover: verifying chat completions...", file=sys.stderr)
    items = [(env, name, info)
             for env in dict.fromkeys(e for e, *_ in ENVS)
             for name, info in desired[env].items()]
    working: dict[str, dict[str, tuple[str | None, int | None]]] = {}
    with ThreadPoolExecutor(max_workers=24) as ex:
        futs = [ex.submit(verify_candidate, it) for it in items]
        for fut in as_completed(futs):
            env, name, served, ctx = fut.result()
            working.setdefault(env, {})[name] = (served, ctx)
    for env in list(desired):
        desired[env] = {n: i for n, i in desired[env].items()
                        if working.get(env, {}).get(n, (None,))[0]}
        for n, i in desired[env].items():
            i["served"], ctx = working[env][n]
            if ctx:
                i["context"] = ctx

    # 3. Current state of the config files.
    alias_rows, skeleton = read_aliases()
    models_data = read_models()
    manifest = {}
    if os.path.exists(MANIFEST_FILE):
        try:
            manifest = json.load(open(MANIFEST_FILE, encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            manifest = {}

    # provider -> env (for matching already-configured models)
    provider_env = {p: e for e, _, _, p, _ in ENVS}

    # 3. What is already configured by the user (never auto-touch, never duplicate)?
    configured_ids: dict[str, set[str]] = {e: set() for e, *_ in ENVS}
    for r in alias_rows:
        spec = r["spec"]
        if "/" in spec:
            provider, mid = spec.split("/", 1)
            e = provider_env.get(provider, r["env"])
            configured_ids.setdefault(e, set()).add(mid)
    for provider, prov in (models_data.get("providers") or {}).items():
        e = provider_env.get(provider)
        if not e:
            continue
        for m in prov.get("models") or []:
            configured_ids.setdefault(e, set()).add(m["id"])

    # 4. Diff: add new, drop previously-discovered-but-gone, keep the rest.
    added, removed = {}, {}
    new_manifest = {}
    for env in dict.fromkeys(e for e, *_ in ENVS):
        old = manifest.get(env, {})
        want = desired[env]
        old_ids = set(old)
        want_ids = set(want)
        # models that left the registry and were added by discover -> remove
        gone = old_ids - want_ids
        # models that are new to us and not already configured -> add
        fresh = want_ids - old_ids - configured_ids[env]
        new_manifest[env] = {i: old[i] for i in old_ids if i in want_ids}
        removed[env] = sorted(gone)
        added[env] = sorted(fresh)

    # 5. Apply: aliases. Drop aliases whose (env, id) is in removed[], then add new.
    used_aliases = {r["alias"] for r in alias_rows}
    removed_keys = {(e, i) for e in removed for i in removed[e]}
    alias_rows = [r for r in alias_rows
                  if (r["env"], r["spec"].split("/", 1)[1]) not in removed_keys]
    # add new aliases
    for env in dict.fromkeys(e for e, *_ in ENVS):
        for mid in added[env]:
            want = desired[env][mid]
            base = slugify(mid)
            alias = base
            if alias in used_aliases:
                alias = f"{base}-{env}"
            used_aliases.add(alias)
            alias_rows.append({
                "alias": alias,
                "spec": f"{want['provider']}/{mid}",
                "url": want["url"],
                "keyvar": want["keyvar"],
                "env": env,
            })
            new_manifest[env][mid] = {
                "alias": alias, "provider": want["provider"], "id": mid,
                "url": want["url"], "baseUrl": want["baseUrl"],
                "served": want.get("served"),
                "context": want["context"], "vision": want["vision"],
                "family": want["family"], "env": env,
            }
    write_aliases(alias_rows, skeleton)

    # 6. Apply: models.json.
    providers = models_data.setdefault("providers", {})
    for env in dict.fromkeys(e for e, *_ in ENVS):
        provider = provider_for_env(env)
        prov = providers.get(provider)
        # drop removed discovered models from the provider
        if prov:
            prov["models"] = [m for m in prov.get("models") or []
                              if (env, m["id"]) not in removed_keys]
        for mid in added[env]:
            want = desired[env][mid]
            if prov is None:
                prov = {"name": f"On-prem {env.title()}", "api": "openai-completions",
                        "baseUrl": f"{want['baseUrl'].rsplit('/', 1)[0]}",
                        "apiKey": f"${want['keyvar']}", "compat": {
                            "thinkingFormat": "chat-template",
                            "supportsReasoningEffort": True}}
                providers[provider] = prov
            entry = {
                "id": mid,
                "name": f"{mid} (discovered, {env})",
                "baseUrl": want["baseUrl"],
                "api": "openai-completions",
                "input": ["text"] + (["image"] if want["vision"] else []),
                "contextWindow": want["context"],
                "maxTokens": max_tokens_for(want["context"]),
                "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            }
            served = want.get("served")
            if served and served != mid:
                entry["samplingParams"] = {"model": served, "temperature": 1}
            existing = [m for m in prov.get("models") or [] if m["id"] == mid]
            if not existing:
                prov.setdefault("models", []).append(entry)
        # refresh the window of models discover added earlier when the server reports a new one
        for mid, rec in new_manifest[env].items():
            if mid in added[env] or not prov:
                continue
            ctx = desired[env][mid]["context"]
            for m in prov.get("models") or []:
                if m["id"] == mid and m.get("contextWindow") != ctx:
                    print(f"  {env}/{mid}: contextWindow {m.get('contextWindow')} -> {ctx}")
                    m["contextWindow"] = ctx
                    m["maxTokens"] = max_tokens_for(ctx)
            rec["context"] = ctx
    write_models(models_data)

    # 7. Write the new manifest.
    with open(MANIFEST_FILE, "w", encoding="utf-8") as f:
        json.dump(new_manifest, f, indent=2, ensure_ascii=False)

    # 8. Summary.
    for env in dict.fromkeys(e for e, *_ in ENVS):
        a, r = added[env], removed[env]
        kept = len(desired[env]) - len(a)
        print(f"{env}: +{len(a)} added, -{len(r)} removed, {kept} kept "
              f"({len(desired[env])} verified chat models)")
        if a:
            print("  added:  " + ", ".join(a))
        if r:
            print("  removed:" + ", ".join(r))
    print("run 'pi models' to see the list (grouped by env + family).")


if __name__ == "__main__":
    main()