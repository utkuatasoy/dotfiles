#!/usr/bin/env bash
# Run pi against an on-prem model.
#   run_pi.sh [alias] [+token ...] [pi args ...]
#
# Model selection (first match wins):
#   1. leading alias arg      run_pi.sh flash ...
#   2. PI_MODEL env           PI_MODEL=glm run_pi.sh
#   3. config/default-model   (written by `pi use <alias>`)
#   4. first reachable model in MODELS order (probe)
#
# Extension tokens:
#   +ext <path>   load an extra extension file/dir
#   +all          normal extension discovery
set -euo pipefail

HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_BIN="$HARNESS/node_modules/.bin/pi"
EXT_DIR="$HARNESS/extensions"
DEFAULT_FILE="$HARNESS/config/default-model"
TIMEOUT=3

# Model aliases live in config/aliases (gitignored; template: config/aliases.example).
# Line format: "<alias>|<provider>/<model id>|<probe url>|<api key env var>"; order = probe preference.
ALIASES="$HARNESS/config/aliases"
[ -f "$ALIASES" ] || { echo "run_pi.sh: missing $ALIASES (cp config/aliases.example config/aliases)" >&2; exit 2; }
MODELS=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"; line="$(echo "$line" | tr -d '[:space:]')"
  [ -n "$line" ] && MODELS+=("$line")
done < "$ALIASES"
[ ${#MODELS[@]} -gt 0 ] || { echo "run_pi.sh: no models in $ALIASES" >&2; exit 2; }

[ -x "$PI_BIN" ] || { echo "run_pi.sh: pi not found at $PI_BIN (run npm install)" >&2; exit 127; }

# Resolve an alias, "provider/id", or bare model id to "provider/id".
resolve() {
  local e a s
  for e in "${MODELS[@]}"; do
    a="${e%%|*}"; s="${e#*|}"; s="${s%%|*}"
    if [ "$1" = "$a" ] || [ "$1" = "$s" ] || [ "$1" = "${s#*/}" ]; then echo "$s"; return 0; fi
  done
  return 1
}

if [ "${1:-}" = "--aliases" ]; then
  for e in "${MODELS[@]}"; do a="${e%%|*}"; s="${e#*|}"; echo "$a|${s%%|*}|${s#*|}"; done
  exit 0
fi

# Subcommands live in shell/pi.zsh; landing here means the shell has a stale copy.
case "${1:-}" in
  help|-h|use|models|ls|config|conf|raw)
    echo "run_pi.sh: '$1' is a shell/pi.zsh subcommand — reload it: source ~/.zshrc" >&2; exit 2 ;;
esac

model=""
if [ $# -gt 0 ] && m="$(resolve "$1")"; then
  model="$m"; shift; src="arg"
elif [ -n "${PI_MODEL:-}" ]; then
  model="$(resolve "$PI_MODEL")" || { echo "run_pi.sh: unknown model '$PI_MODEL'" >&2; exit 2; }
  src="PI_MODEL"
elif [ -s "$DEFAULT_FILE" ]; then
  d="$(tr -d '[:space:]' < "$DEFAULT_FILE")"
  model="$(resolve "$d")" || { echo "run_pi.sh: unknown default '$d' in $DEFAULT_FILE" >&2; exit 2; }
  src="default"
else
  for e in "${MODELS[@]}"; do
    s="${e#*|}"; url="${s#*|}"; url="${url%%|*}"
    # any HTTP status counts as reachable: gateways answer 401 unauthenticated
    if curl -sk -m "$TIMEOUT" -o /dev/null "$url"; then model="${s%%|*}"; break; fi
  done
  [ -n "$model" ] || { echo "run_pi.sh: no model reachable (tried ${#MODELS[@]})" >&2; exit 3; }
  src="first reachable"
fi

ext_args=(-ne)   # no discovery → minimal system prompt
loaded=()
add_ext() {
  [ -e "$1" ] || { echo "run_pi.sh: no extension at $1" >&2; exit 2; }
  ext_args+=(-e "$1"); loaded+=("$(basename "$1")")
}
[ -e "$EXT_DIR/git-guard.ts" ] && add_ext "$EXT_DIR/git-guard.ts"
# superpowers package extension (settings.json packages are skipped by -ne;
# its resources_discover handler registers the superpowers skills)
SUPERPOWERS_EXT="$HOME/.pi/agent/superpowers-manager/installed/.pi/extensions/superpowers.ts"
[ -e "$SUPERPOWERS_EXT" ] && add_ext "$SUPERPOWERS_EXT"
# pi-subagents package extension (same -ne caveat as superpowers)
SUBAGENTS_EXT="$HOME/.pi/agent/npm/node_modules/pi-subagents-j0k3r/index.ts"
[ -e "$SUBAGENTS_EXT" ] && add_ext "$SUBAGENTS_EXT"
[ -z "${PI_NO_HUD:-}" ] && add_ext "$HARNESS/wrappers/hud.ts"

while [ $# -gt 0 ]; do
  case "$1" in
    +all) ext_args=(); loaded=(discovery); shift ;;
    +ext) [ $# -ge 2 ] || { echo "run_pi.sh: +ext needs a path" >&2; exit 2; }
          add_ext "$2"; shift 2 ;;
    *)    break ;;
  esac
done

echo "run_pi.sh: model $model ($src); extensions: ${loaded[*]:-none}" >&2
exec "$PI_BIN" --model "$model" "${ext_args[@]}" "$@"
