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
# $1 = curl timeout in seconds (default 5).
_pi_status() {
  local tmo="${1:-5}" tmp="$(mktemp -d)" i=0 a s u k
  "$PI_HARNESS/run_pi.sh" --aliases | while IFS='|' read -r a s u k; do
    (( i++ ))
    {
      local code
      if [ -z "${(P)k:-}" ]; then code="\$$k not set"
      else
        code="$(curl -sk -m "$tmo" -o /dev/null -w '%{http_code}' -H "Authorization: Bearer ${(P)k}" "$u" 2>/dev/null)"
        case "$code" in 200) code="ok" ;; 000) code="down" ;; 401) code="401 bad key" ;; 403) code="403 no access" ;; esac
      fi
      print -r -- "$a|$s|$code" > "$tmp/$i"
    } &!
  done
  local n="$("$PI_HARNESS/run_pi.sh" --aliases | wc -l | tr -d ' ')" t=0
  while (( t < 60 )) && [ "$(ls "$tmp" | wc -l | tr -d ' ')" -lt "$n" ]; do sleep 0.1; (( t++ )); done
  for i in {1..$n}; do [ -f "$tmp/$i" ] && cat "$tmp/$i"; done
  rm -rf "$tmp"
}

# Interactive model picker. Draws on the tty, reads one key at a time:
#   ↑/↓ or j/k move · 1-9 jump · Enter start · d start + make default · q/Esc cancel
# Sets $_PI_PICK ("provider/id", empty when cancelled), $_PI_PICK_ALIAS and
# $_PI_PICK_DEFAULT (1 when the pick should also become the default model).
_pi_picker() {
  typeset -g _PI_PICK="" _PI_PICK_ALIAS="" _PI_PICK_DEFAULT=""
  local tty=/dev/tty i n key c1 c2 sel=1 mark cand
  [ -w "$tty" ] || tty=/dev/stdout

  local -a al=() sp=() en=() st=()
  local a s u k
  while IFS='|' read -r a s u k; do
    al+=$a sp+=$s
    [[ "$u" == *".test-"* || "$u" == *"-test."* ]] && en+=test || en+=prod
  done < <("$PI_HARNESS/run_pi.sh" --aliases)
  n=$#al
  (( n )) || { print -u2 "no models in config/aliases"; return 1 }

  local -A st_of; local sl
  printf '\r\e[Kfetching model status...' > "$tty"
  while IFS='|' read -r a s sl; do st_of[$a]="$sl"; done < <(_pi_status 2)
  for (( i = 1; i <= n; i++ )); do st+=( "${st_of[$al[i]]:-?}" ); done

  local def="$(cat "$PI_HARNESS/config/default-model" 2>/dev/null)"
  for cand in "$(cat "$PI_HARNESS/config/last-model" 2>/dev/null)" "$def"; do
    [[ -n "$cand" ]] || continue
    for (( i = 1; i <= n; i++ )); do
      [[ "$al[i]" == "$cand" || "$sp[i]" == "$cand" ]] && { sel=$i; break 2 }
    done
  done

  local -a buf; local drawn=0 sel_line=0 cursor_row=0 le row pre
  local dim=$'\e[2m' off=$'\e[0m' grn=$'\e[32m' red=$'\e[31m' bld=$'\e[1m' cyn=$'\e[36m'
  while true; do
    buf=( "${dim}pick a model   ↑/↓ or j/k · 1-$n · Enter start · d start + set as default · q cancel${off}" "" )
    le=""
    for (( i = 1; i <= n; i++ )); do
      if [[ "$en[i]" != "$le" ]]; then
        buf+=( "" "  ${cyn}${en[i]}:${off}" )
        le="$en[i]"
      fi
      mark=" "; [[ "$al[i]" == "$def" || "$sp[i]" == "$def" ]] && mark="*"
      pre="  "; (( i == sel )) && { pre="❯ "; sel_line=${#buf} }
      printf -v row '%s%s %-12s %-44s' "$pre" "$mark" "$al[i]" "$sp[i]"
      if [[ "${st[i]}" == ok ]]; then
        (( i == sel )) && row="${bld}${row}${off}"
        buf+=( "${row}${grn}ok${off}" )
      else
        buf+=( "${dim}${row}${off} ${red}${st[i]}${off}" )
      fi
    done
    # the cursor sits on the previously picked row: go up exactly that far to
    # reach the top of the block again, otherwise the frame is drawn above it
    # and the old rows stay behind (the list looks like it keeps growing)
    (( cursor_row )) && printf '\e[%dA' "$cursor_row" > "$tty"
    for row in "${buf[@]}"; do printf '\r\e[K%s\n' "$row" > "$tty"; done
    drawn=${#buf}
    printf '\e[%dA' "$(( drawn - sel_line ))" > "$tty"
    cursor_row=$sel_line

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
  printf '\e[%dA' "$cursor_row" > "$tty"
  for (( i = 1; i <= drawn; i++ )); do printf '\r\e[K\n' > "$tty"; done
  printf '\e[%dA' "$drawn" > "$tty"
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

# Shared model listing: grouped by env, green ok / red broken.
# $1 = "models" (alias column) or "help" ("pi <alias>" column).
_pi_list_models() {
  local mode="$1" def="$(cat "$PI_HARNESS/config/default-model" 2>/dev/null)"
  local a s st e mark last="" alias_w
  [ "$mode" = help ] && alias_w=14 || alias_w=10
  _pi_status | while IFS='|' read -r a s st; do
    e="${_pi_env_of[$a]:-}"
    if [ "$e" != "$last" ]; then
      print -r -- ""
      print -P "  %F{cyan}${e}:%f"
      last="$e"
    fi
    mark=" "; [ "$a" = "$def" -o "$s" = "$def" ] && mark="*"
    local label="$a"; [ "$mode" = help ] && label="pi $a"
    if [ "$st" = ok ]; then
      printf "  %s \\e[32m%-${alias_w}s\\e[0m %-42s \\e[32mok\\e[0m\n" "$mark" "$label" "$s"
    else
      printf "  %s \\e[2m%-${alias_w}s %-42s\\e[0m \\e[31m%s\\e[0m\n" "$mark" "$label" "$s" "$st"
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
  pi models               list models grouped by env (prod/test), with status
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
  local -a sub; sub=(help use models config raw pick ${(f)"$("$PI_HARNESS/run_pi.sh" --aliases | cut -d'|' -f1)"})
  if (( CURRENT == 2 )); then compadd -a sub
  elif (( CURRENT == 3 )) && [[ $words[2] == use ]]; then
    compadd -- --clear ${(f)"$("$PI_HARNESS/run_pi.sh" --aliases | cut -d'|' -f1)"}
  fi
}
(( $+functions[compdef] )) && compdef _pi pi
