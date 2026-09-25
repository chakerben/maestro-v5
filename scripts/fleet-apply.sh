#!/bin/bash
# ============================================================
# Maestro — fleet-apply.sh
#
# Applique 00-onboard scaffold et/ou 04-doctor à TOUS les projets qui
# utilisent Maestro, sans ouvrir 36 sessions à la main.
#
# Trois actions, cumulables :
#   --settings   déterministe, sans LLM : merge les entrées permissions.deny
#                canoniques et "model": "sonnet" dans .claude/settings.json
#                (idempotent, ne remplace jamais une valeur existante).
#   --doctor     `claude -p "/maestro-core:04-doctor check"` en lecture seule,
#                rapport par projet dans le log.
#   --scaffold   `claude -p "/maestro-core:00-onboard scaffold"` (crée
#                maestro_docs/, le bloc CLAUDE.md, settings) — écrit des
#                fichiers, donc --permission-mode acceptEdits.
# Défaut sans action : --settings --doctor.
#
# USAGE :
#   ./scripts/fleet-apply.sh --list                    # qui est concerné
#   ./scripts/fleet-apply.sh --dry-run --all           # montre, n'exécute rien
#   ./scripts/fleet-apply.sh --settings --all          # gratuit, sans LLM
#   ./scripts/fleet-apply.sh --doctor ~/Documents/Projects/myproject
#   ./scripts/fleet-apply.sh --scaffold --doctor --all --jobs 2
#
# Options : --jobs N (défaut 1 : un projet à la fois — la politique de
# flotte dit "sonnet en parallèle OK, pas de raisonnement lourd en
# parallèle" ; 2 est raisonnable, au-delà tu paies pour rien),
# --model sonnet|fable|opus (défaut sonnet : doctor et scaffold sont
# mécaniques), --timeout SEC (défaut 600 par projet).
#
# Logs : ~/.maestro/fleet/<date>/<projet>.<action>.log + summary.tsv
# ============================================================

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/fleet.sh
. "$REPO_ROOT/scripts/lib/fleet.sh"

DRY_RUN=0; ALL=0; LIST_ONLY=0; JOBS=1; MODEL="sonnet"; TIMEOUT=600
DO_SETTINGS=0; DO_DOCTOR=0; DO_SCAFFOLD=0
PROJECTS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)  DRY_RUN=1 ;;
    --all)      ALL=1 ;;
    --list)     LIST_ONLY=1 ;;
    --settings) DO_SETTINGS=1 ;;
    --doctor)   DO_DOCTOR=1 ;;
    --scaffold) DO_SCAFFOLD=1 ;;
    --jobs)     shift; JOBS="${1:-1}" ;;
    --model)    shift; MODEL="${1:-sonnet}" ;;
    --timeout)  shift; TIMEOUT="${1:-600}" ;;
    -h|--help)  sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "option inconnue : $1 (voir --help)" >&2; exit 2 ;;
    *)  PROJECTS+=("$1") ;;
  esac
  shift
done
if [ "$DO_SETTINGS$DO_DOCTOR$DO_SCAFFOLD" = "000" ]; then DO_SETTINGS=1; DO_DOCTOR=1; fi
case "$MODEL" in sonnet|fable|opus) ;; *) echo "--model : sonnet|fable|opus" >&2; exit 2 ;; esac

B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
ok()   { echo -e "  ${G}✅ $1${N}"; }
warn() { echo -e "  ${Y}⚠️  $1${N}"; }
err()  { echo -e "  ${R}❌ $1${N}"; }
act()  { if [ "$DRY_RUN" = "1" ]; then echo -e "  ${B}[dry-run] $1${N}"; else echo -e "  ${B}→ $1${N}"; fi; }

command -v python3 >/dev/null || { err "python3 requis"; exit 1; }
if [ "$DO_DOCTOR$DO_SCAFFOLD" != "00" ] && [ "$DRY_RUN" = "0" ]; then
  command -v claude >/dev/null || { err "claude CLI introuvable (requis pour --doctor/--scaffold)"; exit 1; }
fi

# ── Timeout portable ──────────────────────────────────────────────────────
# macOS stock n'a pas `timeout` (GNU coreutils only). On utilise `timeout` si
# présent, sinon `gtimeout` (brew install coreutils), sinon un wrapper bash
# pur (lance en arrière-plan, tue au bout de N s) qui marche partout.
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  TIMEOUT_BIN=""
fi

run_with_timeout() {  # $1 seconds, rest... command
  local secs="$1"; shift
  if [ -n "$TIMEOUT_BIN" ]; then
    "$TIMEOUT_BIN" "$secs" "$@"
    return $?
  fi
  # Fallback portable : lance en arrière-plan, tue le groupe au bout de $secs.
  "$@" &
  local pid=$!
  (
    sleep "$secs"
    kill -TERM "$pid" 2>/dev/null
    sleep 2
    kill -KILL "$pid" 2>/dev/null
  ) &
  local watcher=$!
  local rc=0
  wait "$pid" 2>/dev/null; rc=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  # SIGTERM (143) ou tué -> on le reporte comme un timeout (124), même
  # convention que GNU timeout, pour que le reste du script s'y retrouve.
  if [ $rc -eq 143 ] || [ $rc -eq 137 ]; then rc=124; fi
  return $rc
}

# ── Sélection des projets ────────────────────────────────────────────────
if [ "$ALL" = "1" ] || [ "$LIST_ONLY" = "1" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    [ -n "$(plugins_of "$d")" ] && PROJECTS+=("$d")
  done < <(discover)
fi
if [ "${#PROJECTS[@]}" -eq 0 ]; then
  err "aucun projet. Donne un chemin, ou --all / --list."; exit 1
fi
if [ "$LIST_ONLY" = "1" ]; then
  echo "Projets utilisant @$MARKETPLACE (${#PROJECTS[@]}) :"
  for p in "${PROJECTS[@]}"; do
    printf '  %-60s %s\n' "$p" "$(plugins_of "$p" | sed "s/@$MARKETPLACE//" | tr '\n' ' ')"
  done
  exit 0
fi

RUN_DIR="$HOME/.maestro/fleet/$(date +%Y%m%d-%H%M%S)"
[ "$DRY_RUN" = "1" ] || mkdir -p "$RUN_DIR"
SUMMARY="$RUN_DIR/summary.tsv"
[ "$DRY_RUN" = "1" ] || printf 'project\taction\tstatus\tseconds\tlog\n' > "$SUMMARY"

# ── --settings : merge JSON déterministe (même contrat que 04-scaffold 4b/4c) ──
apply_settings() {
  python3 - "$1" "$DRY_RUN" <<'PY'
import json, os, sys
proj, dry = sys.argv[1], sys.argv[2] == "1"
p = os.path.join(proj, ".claude", "settings.json")
DENY = ["Bash(rm -rf /)", "Bash(rm -rf /*)", "Bash(rm -rf ~)", "Bash(rm -rf ~/*)",
        "Bash(rm -rf $HOME)", "Bash(curl * | bash)", "Bash(curl * | sh)",
        "Bash(wget * | bash)", "Bash(wget * | sh)", "Bash(git push --force*)",
        "Bash(git push -f*)"]
try:
    raw = open(p).read() if os.path.exists(p) else "{}"
    d = json.loads(raw) if raw.strip() else {}
except Exception as e:
    print(f"MALFORMED {p}: {e}"); sys.exit(3)
if not isinstance(d, dict):
    print(f"MALFORMED {p}: not an object"); sys.exit(3)
changes = []
perms = d.setdefault("permissions", {})
if not isinstance(perms, dict):
    print(f"MALFORMED {p}: permissions is not an object"); sys.exit(3)
deny = perms.setdefault("deny", [])
if not isinstance(deny, list):
    print(f"MALFORMED {p}: permissions.deny is not a list"); sys.exit(3)
missing = [x for x in DENY if x not in deny]
if missing:
    deny.extend(missing); changes.append(f"permissions.deny +{len(missing)}")
note = ""
if "model" not in d:
    d["model"] = "sonnet"; changes.append('model=sonnet')
elif d["model"] != "sonnet":
    note = f" (model kept: {d['model']!r} — the ladder assumes sonnet)"
if not changes:
    print("UNCHANGED" + note); sys.exit(0)
if dry:
    print("WOULD " + ", ".join(changes) + note); sys.exit(0)
os.makedirs(os.path.dirname(p), exist_ok=True)
tmp = p + ".tmp"
with open(tmp, "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False); f.write("\n")
os.replace(tmp, p)
print("CHANGED " + ", ".join(changes) + note)
PY
}

# ── Une action LLM sur un projet, headless ───────────────────────────────
run_claude() {  # $1 project, $2 action (doctor|scaffold)
  local proj="$1" action="$2" prompt perm log t0 rc
  case "$action" in
    doctor)   prompt='/maestro-core:04-doctor check'
              perm=(--allowedTools "Read,Glob,Grep,Bash") ;;
    scaffold) prompt='/maestro-core:00-onboard scaffold — non-interactive: answer yes to writing permissions.deny and "model": "sonnet"; never overwrite an existing value; report created vs skipped.'
              perm=(--permission-mode acceptEdits --allowedTools "Read,Glob,Grep,Bash,Write,Edit") ;;
  esac
  log="$RUN_DIR/$(basename "$proj").$action.log"
  act "cd $proj && claude -p \"$prompt\" --model $MODEL ${perm[*]}"
  [ "$DRY_RUN" = "1" ] && return 0
  t0=$(date +%s)
  ( cd "$proj" && run_with_timeout "$TIMEOUT" claude -p "$prompt" --model "$MODEL" "${perm[@]}" ) >"$log" 2>&1
  rc=$?
  printf '%s\t%s\t%s\t%s\t%s\n' "$proj" "$action" "$rc" "$(( $(date +%s) - t0 ))" "$log" >> "$SUMMARY"
  if [ $rc -eq 0 ]; then ok "$action ok ($(( $(date +%s) - t0 ))s) → $log"
  elif [ $rc -eq 124 ]; then err "$action timeout ${TIMEOUT}s → $log"
  else err "$action exit $rc → $log"; fi
  return $rc
}

one_project() {
  local proj="$1"
  echo -e "\n${B}■ $proj${N}  ($(plugins_of "$proj" | sed "s/@$MARKETPLACE//" | tr '\n' ' '))"
  if [ "$DO_SETTINGS" = "1" ]; then
    local out; out="$(apply_settings "$proj")"; local rc=$?
    case "$rc:$out" in
      0:UNCHANGED*) ok "settings: déjà conforme${out#UNCHANGED}" ;;
      0:WOULD*)     act "settings: ${out#WOULD }" ;;
      0:CHANGED*)   ok "settings: ${out#CHANGED }" ;;
      *)            err "settings: $out" ;;
    esac
    [ "$DRY_RUN" = "1" ] || printf '%s\tsettings\t%s\t0\t-\n' "$proj" "$rc" >> "$SUMMARY"
  fi
  [ "$DO_SCAFFOLD" = "1" ] && run_claude "$proj" scaffold
  [ "$DO_DOCTOR" = "1" ]   && run_claude "$proj" doctor
  return 0
}

echo "Maestro fleet — ${#PROJECTS[@]} projet(s), actions:$( [ $DO_SETTINGS = 1 ] && echo -n ' settings')$( [ $DO_SCAFFOLD = 1 ] && echo -n ' scaffold')$( [ $DO_DOCTOR = 1 ] && echo -n ' doctor'), model $MODEL, jobs $JOBS"
[ "$DRY_RUN" = "1" ] || echo "Logs : $RUN_DIR"

if [ "$JOBS" -le 1 ]; then
  for p in "${PROJECTS[@]}"; do one_project "$p"; done
else
  # Parallélisme borné, bash 3.2 : on lance JOBS sous-shells max.
  running=0
  for p in "${PROJECTS[@]}"; do
    one_project "$p" &
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n 2>/dev/null || wait; running=$((running - 1)); fi
  done
  wait
fi

if [ "$DRY_RUN" = "0" ]; then
  echo
  echo "── Résumé ($SUMMARY)"
  awk -F'\t' 'NR>1 { if ($3==0) ok[$2]++; else ko[$2]++ } END { for (a in ok) printf "  %-9s ok %d\n", a, ok[a]; for (a in ko) printf "  %-9s KO %d\n", a, ko[a] }' "$SUMMARY"
  if [ "$DO_DOCTOR" = "1" ]; then
    echo "── Doctor : projets avec 🔴/🟠"
    grep -lE '🔴|🟠' "$RUN_DIR"/*.doctor.log 2>/dev/null | sed 's|.*/||; s|\.doctor\.log||; s|^|  |' || echo "  aucun"
  fi
fi
