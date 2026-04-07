#!/usr/bin/env bash
# SessionStart hook: inject project docs + recent git history into Claude's context
set -uo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | /usr/bin/python3 -c "import sys,json;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"
cd "$CWD" 2>/dev/null || exit 0

OUT=""
append() { OUT+="$1"$'\n'; }

append "# Auto-loaded project context"
append ""

for f in OVERVIEW.md README.md CLAUDE.md; do
  if [ -f "$f" ]; then
    append "## $f"
    append '```markdown'
    append "$(cat "$f")"
    append '```'
    append ""
    break
  fi
done

if [ -d .git ]; then
  append "## Last 5 commits"
  append '```'
  append "$(git log -5 --stat --pretty=format:'%h %an %ar%n%s%n' --no-color 2>/dev/null)"
  append '```'
fi

/usr/bin/python3 - "$OUT" <<'PY'
import json, sys
ctx = sys.argv[1]
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ctx
  }
}))
PY
