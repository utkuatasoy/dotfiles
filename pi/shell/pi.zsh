# pi harness shell helpers — source from ~/.zshrc:
#   source <harness-root>/shell/pi.zsh
#
#   pi                      start with default / first reachable model
#   pi <alias> [args]       start with a model (ds | flash | glm)
#   pi use <alias>          set persistent default model
#   pi use --clear          back to "first reachable"
#   pi models               list aliases, default and reachability
#   pi config               edit config/models.json in $EDITOR
#   pi raw [args]           run the pi binary directly (no launcher)

PI_HARNESS="${PI_HARNESS:-${${(%):-%x}:A:h:h}}"

# Prints "<alias>|<provider/id>|<status>" per model; probes run in parallel.
# A model is "ok" only when a real 1-token chat completion returns choices
# (same check as discover.py) — /v1/models alone also answers on broken routes.
# $1 = curl timeout in seconds (default 10).
_pi_status() {
  local tmo="${1:-10}" tmp="$(mktemp -d)" i=0 a s u k
  "$PI_HARNESS/run_pi.sh" --aliases | while IFS='|' read -r a s u k; do
    (( i++ ))
    {
      local code body
      if [ -z "${(P)k:-}" ]; then code="\$$k not set"
      else
        body="$(curl -sk -m "$tmo" -w $'\n%{http_code}' -X POST \
          -H "Authorization: Bearer ${(P)k}" -H 'Content-Type: application/json' \
          -d "{\"model\":\"${s#*/}\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":1}" \
          "${u%/models}/chat/completions" 2>/dev/null)"
        code="${body##*$'\n'}"
        case "$code" in
          200) [[ "$body" == *'"choices"'* ]] && code="ok" || code="200 no choices" ;;
          000|"") code="down" ;;
          401) code="401 bad key" ;;
          403) code="403 no access" ;;
          404) code="404 not served" ;;
        esac
      fi
      # write + rename so the poll below never counts a half-written file
      print -r -- "$a|$s|$code" > "$tmp/.$i" && mv "$tmp/.$i" "$tmp/$i"
    } &!
  done
  local n="$("$PI_HARNESS/run_pi.sh" --aliases | wc -l | tr -d ' ')" t=0
  while (( t < (tmo + 1) * 10 )) && [ "$(ls "$tmp" | wc -l | tr -d ' ')" -lt "$n" ]; do sleep 0.1; (( t++ )); done
  for i in {1..$n}; do [ -f "$tmp/$i" ] && cat "$tmp/$i"; done
  rm -rf "$tmp"
}

# Truncate a line that may contain \e[..m escapes to $1 visible columns.
# Escapes are copied but not counted; a reset is always appended so a
# truncated line can never leak style into the next one.
_pi_clip() {
  local max=$1 s=$2 out="" n=0 i=0 c
  while (( i < ${#s} )); do
    c="${s[i+1]}"; (( i++ ))
    if [[ "$c" == $'\e' ]]; then
      out+="$c"
      while (( i < ${#s} )); do
        c="${s[i+1]}"; (( i++ )); out+="$c"
        [[ "$c" == m ]] && break
      done
    elif (( n >= max )); then
      break
    else
      out+="$c"; (( n++ ))
    fi
  done
  print -r -- "${out}"$'\e[0m'
}

# Interactive model picker. Draws on the tty, reads one key at a time:
#   ↑/↓ or j/k move · 1-9 jump · Enter start · d start + make default · q/Esc cancel
# Sets $_PI_PICK ("provider/id", empty when cancelled), $_PI_PICK_ALIAS and
# $_PI_PICK_DEFAULT (1 when the pick should also become the default model).
_pi_picker() {
  typeset -g _PI_PICK="" _PI_PICK_ALIAS="" _PI_PICK_DEFAULT=""
  local tty=/dev/tty i n key c1 c2 sel=1 mark cand
  [ -w "$tty" ] || tty=/dev/stdout

  local -a al=() sp=() en=() fam=() st=()
  local a s u k
  while IFS='|' read -r a s u k; do
    al+=$a sp+=$s
    [[ "$u" == *".test-"* || "$u" == *"-test."* ]] && en+=test || en+=prod
    fam+=("$(_pi_family "${s#*/}")")
  done < <("$PI_HARNESS/run_pi.sh" --aliases)
  n=$#al
  (( n )) || { print -u2 "no models in config/aliases"; return 1 }

  local -A st_of; local sl
  printf '\r\e[Kfetching model status...' > "$tty"
  while IFS='|' read -r a s sl; do st_of[$a]="$sl"; done < <(_pi_status 6)
  for (( i = 1; i <= n; i++ )); do st+=( "${st_of[$al[i]]:-?}" ); done

  # Stable order env -> family -> file order, so each prod:/test: and family
  # header appears exactly once (aliases are otherwise prod, test, prod, test…).
  local -a pk=() po=() oal=() osp=() oen=() ofam=() ost=()
  for (( i = 1; i <= n; i++ )); do
    printf -v k '%s%c%s%c%05d' "$en[i]" $'\x1f' "$fam[i]" $'\x1f' "$i"
    pk+=$k
  done
  po=(${(on)pk})
  for k in $po; do
    local idx="${k##*$'\x1f'}"
    oal+=$al[$idx] osp+=$sp[$idx] oen+=$en[$idx] ofam+=$fam[$idx] ost+=$st[$idx]
  done
  al=("${oal[@]}") sp=("${osp[@]}") en=("${oen[@]}") fam=("${ofam[@]}") st=("${ost[@]}")

  # Only live models in the picker: rows that probe ok. `pi models` / `pi help`
  # still list everything with its status for diagnostics.
  local -a fal=() fsp=() fen=() ffam=() fst=()
  for (( i = 1; i <= n; i++ )); do
    [[ "${st[i]}" == ok ]] || continue
    fal+=$al[i] fsp+=$sp[i] fen+=$en[i] ffam+=$fam[i] fst+=$st[i]
  done
  al=("${fal[@]}") sp=("${fsp[@]}") en=("${fen[@]}") fam=("${ffam[@]}") st=("${fst[@]}")
  n=$#al
  (( n )) || { print -u2 "no live models right now (see: pi models)"; return 1 }

  local def="$(cat "$PI_HARNESS/config/default-model" 2>/dev/null)"
  for cand in "$(cat "$PI_HARNESS/config/last-model" 2>/dev/null)" "$def"; do
    [[ -n "$cand" ]] || continue
    for (( i = 1; i <= n; i++ )); do
      [[ "$al[i]" == "$cand" || "$sp[i]" == "$cand" ]] && { sel=$i; break 2 }
    done
  done

  local -a buf; local le lf row pre j
  local rendered_n=0 sel_line nb content_n ctop vis rel
  local dim=$'\e[2m' off=$'\e[0m' grn=$'\e[32m' red=$'\e[31m' bld=$'\e[1m' cyn=$'\e[36m'
  # Alias column as wide as the longest alias, so long names don't shift rows.
  local aw=0; for a in $al; do (( ${#a} > aw )) && aw=${#a}; done
  # A line wider than the terminal wraps to two physical lines and breaks the
  # redraw math (old frames pile up). Clip every line to the width instead.
  local cols=$(( ${COLUMNS:-80} - 1 ))
  # Viewport: bounded so the frame never exceeds the terminal height.
  local max_vis=$(( ${LINES:-24} - 5 )); (( max_vis < 4 )) && max_vis=4
  # NOTE: never `local x` (without a value) inside the loop: zsh prints
  # "x=value" for an already-set name, which corrupts the frame.
  printf '\e[?25l' > "$tty"                                 # hide cursor
  trap 'printf "\e[?25h" > /dev/tty 2>/dev/null' EXIT INT
  while true; do
    buf=( "$(_pi_clip "$cols" "${dim}pick a model   ↑/↓ or j/k · 1-$n · Enter start · d start + set as default · q cancel${off}")" "" )
    le="" lf="" sel_line=0
    for (( i = 1; i <= n; i++ )); do
      if [[ "$en[i]" != "$le" ]]; then
        buf+=( "" "$(_pi_clip "$cols" "  ${cyn}${en[i]}:${off}")" )
        le="$en[i]"; lf=""
      fi
      if [[ "$fam[i]" != "$lf" ]]; then
        buf+=( "$(_pi_clip "$cols" "      ${bld}${fam[i]}${off}")" )
        lf="$fam[i]"
      fi
      mark=" "; [[ "$al[i]" == "$def" || "$sp[i]" == "$def" ]] && mark="*"
      pre="        "; (( i == sel )) && pre="❯       "
      printf -v row "%s%s %-${aw}s  %-44s" "$pre" "$mark" "$al[i]" "$sp[i]"
      if [[ "${st[i]}" == ok ]]; then
        (( i == sel )) && row="${bld}${row}${off}"
        buf+=( "$(_pi_clip "$cols" "${row}${grn}ok${off}")" )
      else
        buf+=( "$(_pi_clip "$cols" "${dim}${row}${off} ${red}${st[i]}${off}")" )
      fi
      (( i == sel )) && sel_line=${#buf}
    done
    # Window the content lines (buf[3..]) around the selected row.
    nb=${#buf}; content_n=$(( nb - 2 )); ctop=0
    vis=$content_n; (( vis > max_vis )) && vis=$max_vis
    if (( content_n > max_vis )); then
      rel=$(( sel_line - 3 ))                               # 0-based content index
      ctop=$(( rel - vis + 1 )); (( ctop < 0 )) && ctop=0
      (( ctop > content_n - vis )) && ctop=$(( content_n - vis ))
    fi
    rendered_n=$(( 2 + vis ))
    # Cursor always rests on the frame's first line between redraws.
    for (( j = 1; j <= rendered_n; j++ )); do
      printf '\r\e[K%s\n' "${buf[$(( j >= 3 ? j + ctop : j ))]}" > "$tty"
    done
    printf '\e[%dA' "$rendered_n" > "$tty"

    read -rs -k 1 key || break
    case "$key" in
      $'\r'|$'\n') _PI_PICK="${sp[sel]}"; _PI_PICK_ALIAS="${al[sel]}"; break ;;
      q|Q) break ;;
      d|D) _PI_PICK="${sp[sel]}"; _PI_PICK_ALIAS="${al[sel]}"; _PI_PICK_DEFAULT=1; break ;;
      k|K) (( sel = sel == 1 ? n : sel - 1 )) ;;
      j|J) (( sel = sel == n ? 1 : sel + 1 )) ;;
      $'\e')
        read -rs -k 1 -t 0.05 c1 && read -rs -k 1 -t 0.05 c2 || break
        case "$c1$c2" in
          '[A'|'OA') (( sel = sel == 1 ? n : sel - 1 )) ;;
          '[B'|'OB') (( sel = sel == n ? 1 : sel + 1 )) ;;
        esac ;;
      [1-9]) (( key <= n )) && sel=$key ;;
    esac
  done

  # wipe the menu, leaving the cursor where it started
  for (( j = 1; j <= rendered_n; j++ )); do printf '\r\e[K\n' > "$tty"; done
  (( rendered_n )) && printf '\e[%dA' "$rendered_n" > "$tty"
  printf '\e[?25h' > "$tty"                                 # show cursor
  trap - EXIT INT
}

# Pick a model, remember it, optionally make it the default, then start pi.
# Extra args are forwarded to the launcher:  pi pick --thinking max
_pi_pick_and_run() {
  _pi_picker || return
  [ -n "$_PI_PICK" ] || return 130                      # cancelled
  print -r -- "$_PI_PICK_ALIAS" > "$PI_HARNESS/config/last-model" 2>/dev/null
  if [ -n "$_PI_PICK_DEFAULT" ]; then
    print -r -- "$_PI_PICK_ALIAS" > "$PI_HARNESS/config/default-model"
    print "default model: $_PI_PICK_ALIAS"
  fi
  "$PI_HARNESS/run_pi.sh" "$_PI_PICK" "$@"
}

# Family of a model id (the part after provider/): deepseek-v4-flash-0731 -> deepseek.
# Strips ci-/llm- prefixes, matches a known family table, else the first word.
_pi_family() {
  local n="$1" f
  n="${(L)n}"
  n="${n#ci-}"; n="${n#llm-}"
  local -a fams
  fams=(deepseek glm qwen gemma llama minimax mimo gpt-oss kimi step rune ornith muse \
        diffusion dots bge e5 snowflake whisper parakeet fastpitch sortformer stt \
        nemotron turkish-gemma translategemma)
  for f in $fams; do
    [[ "$n" == "$f"* ]] && { print -r -- "$f"; return 0 }
  done
  print -r -- "${n%%[^a-z0-9]*}"
}

# env per alias, from the probe URL: *.test-* or *-test.* = test, else prod.
# The second form is the cluster route style (…-ai-platform-test.apps.<cluster>).
# Fills the globals _pi_env_of (assoc) and _pi_order (aliases in file order).
_pi_envs() {
  local a s u k
  typeset -gA _pi_env_of _pi_seen
  typeset -ga _pi_order
  _pi_env_of=( ) _pi_seen=( ) _pi_order=( )
  "$PI_HARNESS/run_pi.sh" --aliases | while IFS='|' read -r a s u k; do
    if [[ "$u" == *".test-"* || "$u" == *"-test."* ]]; then _pi_env_of[$a]=test; else _pi_env_of[$a]=prod; fi
    [ -n "${_pi_seen[$a]:-}" ] || { _pi_order+=$a; _pi_seen[$a]=1 }
  done
}

# Shared model listing: grouped by env + family, green ok / red broken.
# $1 = "models" (alias column) or "help" ("pi <alias>" column).
_pi_list_models() {
  local mode="$1" def="$(cat "$PI_HARNESS/config/default-model" 2>/dev/null)"
  local a s st e f mark last="" lastfam="" alias_w=0 k row seq=0 pfx=""
  [ "$mode" = help ] && pfx="pi "
  # Buffer + stable-sort by env -> family -> file order so prod:/test: and
  # family headers each appear exactly once.
  local -a rows=()
  while IFS='|' read -r a s st; do
    e="${_pi_env_of[$a]:-}"
    printf -v k '%s%c%s%c%05d%c%s|%s|%s' "$e" $'\x1f' "$(_pi_family "${s#*/}")" $'\x1f' "$seq" $'\x1f' "$a" "$s" "$st"
    rows+=$k
    (( seq++ ))
    (( ${#pfx} + ${#a} > alias_w )) && alias_w=$(( ${#pfx} + ${#a} ))
  done < <([ -t 2 ] && printf '\r\e[Kprobing models (1-token chat)...' >&2; _pi_status)
  [ -t 2 ] && printf '\r\e[K' >&2
  for row in ${(on)rows}; do
    row="${row#*$'\x1f'}"; row="${row#*$'\x1f'}"; row="${row#*$'\x1f'}"
    a="${row%%|*}"; row="${row#*|}"; s="${row%%|*}"; st="${row#*|}"
    e="${_pi_env_of[$a]:-}"; f="$(_pi_family "${s#*/}")"
    if [ "$e" != "$last" ]; then
      print -r -- ""
      print -P "  %F{cyan}${e}:%f"
      last="$e"; lastfam=""
    fi
    if [ "$f" != "$lastfam" ]; then
      print -P "      %F{green}${f}:%f"
      lastfam="$f"
    fi
    mark=" "; [ "$a" = "$def" -o "$s" = "$def" ] && mark="*"
    local label="$pfx$a"
    if [ "$st" = ok ]; then
      printf "        %s \e[32m%-${alias_w}s\e[0m %-42s \e[32mok\e[0m\n" "$mark" "$label" "$s"
    else
      printf "        %s \e[2m%-${alias_w}s %-42s\e[0m \e[31m%s\e[0m\n" "$mark" "$label" "$s" "$st"
    fi
  done
}
pi() {
  local launcher="$PI_HARNESS/run_pi.sh" def_file="$PI_HARNESS/config/default-model"
  case "${1:-}" in
    use)
      [ -n "${2:-}" ] || { echo "usage: pi use <alias>|--clear" >&2; return 2; }
      if [ "$2" = "--clear" ]; then rm -f "$def_file"; echo "default cleared (first reachable)"; return; fi
      "$launcher" --aliases | cut -d'|' -f1,2 | tr '|' '\n' | grep -qx -- "$2" \
        || { echo "unknown model '$2' (see: pi models)" >&2; return 2; }
      print -r -- "$2" > "$def_file"; echo "default model: $2" ;;
    models|ls)
      _pi_envs
      _pi_list_models models ;;
    help|-h)
      local def="$(cat "$def_file" 2>/dev/null)"
      print "pi harness — $PI_HARNESS\n\nModels (* = default):"
      _pi_envs
      _pi_list_models help
      cat <<EOF

Usage:
  pi                      pick a model — Enter starts it (default: ${def:-none})
  pi <alias> [args]       start with a model ($("$launcher" --aliases | cut -d'|' -f1 | paste -sd'|' -))
  pi <alias> -p "..."     one-shot prompt, print and exit
  pi <alias> --thinking <off|low|high|max>

  pi pick [args]          force the picker (even when PI_MODEL is set)
  pi use <alias>          set persistent default model
  pi use --clear          back to "first reachable"
  pi models               list models grouped by env+family (prod/test), with status
  pi discover             sync config/aliases + models.json with the model registry
  pi token <JWT>          save the model registry token for pi discover
  pi config               edit config/models.json in \$EDITOR
  pi raw [args]           run the pi binary directly (e.g. pi raw --help)
  pi help                 this help

  +ext <path>             load an extra extension    (pi flash +ext ./my-ext.ts)
  +all                    normal extension discovery
  PI_MODEL=<alias> pi     one-off model via env
  PI_NO_PICKER=1 pi       start the default model, no picker
  PI_NO_HUD=1 pi          start without the HUD footer

  In session: /model to switch, /hud toggle HUD footer, /help for pi commands.
EOF
      ;;
    config|conf) ${EDITOR:-vi} "$PI_HARNESS/config/models.json" ;;
    token)
      [ -n "${2:-}" ] || { echo "usage: pi token <JWT>" >&2; return 2; }
      print -r -- "$2" > "$PI_HARNESS/config/registry-token"
      chmod 600 "$PI_HARNESS/config/registry-token"
      echo "token saved ($((${#2})) chars) — next: pi discover" ;;
    discover)
      shift
      if ! command -v python3 >/dev/null 2>&1; then
        echo "pi discover needs python3" >&2; return 2
      fi
      python3 "$PI_HARNESS/discover.py" "$@" ;;
    raw) shift; "$PI_HARNESS/node_modules/.bin/pi" "$@" ;;
    pick) shift; _pi_pick_and_run "$@" ;;
    "")
      if [ -t 0 ] && [ -z "${PI_MODEL:-}" ] && [ -z "${PI_NO_PICKER:-}" ]; then
        _pi_pick_and_run
      else
        "$launcher"
      fi ;;
    *) "$launcher" "$@" ;;
  esac
}

_pi() {
  local -a sub; sub=(help use models config raw pick discover token ${(f)"$("$PI_HARNESS/run_pi.sh" --aliases | cut -d'|' -f1)"})
  if (( CURRENT == 2 )); then compadd -a sub
  elif (( CURRENT == 3 )) && [[ $words[2] == use ]]; then
    compadd -- --clear ${(f)"$("$PI_HARNESS/run_pi.sh" --aliases | cut -d'|' -f1)"}
  fi
}
(( $+functions[compdef] )) && compdef _pi pi
