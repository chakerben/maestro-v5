#!/bin/bash
# ============================================================
# Maestro — update-projects-5.4.0.sh
#
# `claude plugin marketplace update` ne rafraîchit que le CATALOGUE.
# Les copies installées restent à leur version d'installation — d'où les
# 5.3.0 dans `claude plugin list`. Ce script fait le vrai upgrade, projet
# par projet, car un plugin installé --scope project vit dans le
# .claude/settings.json de CHAQUE projet.
#
# USAGE :
#   ./scripts/update-projects-5.4.0.sh --list       # quels projets sont concernés
#   ./scripts/update-projects-5.4.0.sh --dry-run    # montre les commandes, n'exécute rien
#   ./scripts/update-projects-5.4.0.sh <projet>     # un seul projet (commence par là)
#   ./scripts/update-projects-5.4.0.sh --all        # tous
#
# Ne touche à aucun fichier : il n'appelle que `claude plugin update`.
# ============================================================

set -uo pipefail

PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Documents/Projects}"
MARKETPLACE="maestro"
EXPECTED="5.4.0"
DRY_RUN=0; ALL=0; LIST_ONLY=0
PROJECTS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --all)     ALL=1 ;;
    --list)    LIST_ONLY=1 ;;
    -*) echo "option inconnue : $arg (--dry-run, --all, --list)" >&2; exit 2 ;;
    *)  PROJECTS+=("$arg") ;;
  esac
done

B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
ok()   { echo -e "  ${G}✅ $1${N}"; }
warn() { echo -e "  ${Y}⚠️  $1${N}"; }
err()  { echo -e "  ${R}❌ $1${N}"; }
act()  { if [ "$DRY_RUN" = "1" ]; then echo -e "  ${B}[dry-run] $1${N}"; else echo -e "  ${B}→ $1${N}"; fi; }

command -v claude >/dev/null || { err "claude CLI introuvable"; exit 1; }
command -v python3 >/dev/null || { err "python3 requis"; exit 1; }

# Quels plugins maestro ce projet déclare-t-il ?
plugins_of() {
  python3 - "$1" <<'PY' 2>/dev/null
import json, sys, os
p = os.path.join(sys.argv[1], ".claude", "settings.json")
try:
    d = json.load(open(p))
except Exception:
    sys.exit(0)
for k in (d.get("enabledPlugins") or {}):
    name, _, mk = k.partition("@")
    if mk == "maestro":
        print(name)
PY
}

# Les projets que Claude Code connaît lui-même (~/.claude.json). C'est de là
# que sortent les entrées "Scope: project" de `claude plugin list`, donc c'est
# une source plus fiable qu'un scan de dossier.
known_projects() {
  python3 - <<'PYK' 2>/dev/null
import json, os
try:
    d = json.load(open(os.path.expanduser("~/.claude.json")))
except Exception:
    raise SystemExit(0)
for path in (d.get("projects") or {}):
    if os.path.isdir(path):
        print(path)
PYK
}

# Découverte = scan de PROJECTS_ROOT (profondeur 2) + projets connus, dédoublonnés.
discover() {
  { [ -d "$PROJECTS_ROOT" ] && find "$PROJECTS_ROOT" -maxdepth 2 -mindepth 1 -type d -name '.claude' -exec dirname {} \; 2>/dev/null
    known_projects
  } | sort -u
}

if [ "$ALL" = "1" ] || [ "$LIST_ONLY" = "1" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    [ -n "$(plugins_of "$d")" ] && PROJECTS+=("$d")
  done < <(discover)
fi

if [ "${#PROJECTS[@]}" -eq 0 ]; then
  if [ "$ALL" = "1" ] || [ "$LIST_ONLY" = "1" ]; then
    err "aucun projet ne déclare de plugin @$MARKETPLACE"
    echo "     Cherché dans :"
    if [ -d "$PROJECTS_ROOT" ]; then
      echo "       - $PROJECTS_ROOT (existe, $(discover | wc -l | tr -d ' ') dossier(s) avec un .claude/)"
    else
      echo "       - $PROJECTS_ROOT — CE DOSSIER N'EXISTE PAS"
    fi
    echo "       - projets connus de Claude Code (~/.claude.json) : $(known_projects | wc -l | tr -d ' ')"
    echo "     Si tes projets sont ailleurs :"
    echo "       PROJECTS_ROOT=/chemin/vers/tes/projets $0 --list"
  else
    err "aucun projet indiqué — rien n'a été cherché."
    echo ""
    echo "     $0 --list              # voir les projets concernés"
    echo "     $0 <projet>            # en mettre un seul à jour"
    echo "     $0 --all --dry-run     # simuler sur tous"
    echo "     $0 --all               # tous, pour de vrai"
  fi
  exit 1
fi

if [ "$LIST_ONLY" = "1" ]; then
  echo "Projets déclarant des plugins @$MARKETPLACE (${#PROJECTS[@]}) :"
  echo "  ✔ = activé dans le settings.json du projet · ✘ = déclaré mais désactivé"
  echo ""
  DIS_TOTAL=0
  for p in "${PROJECTS[@]}"; do
    LINE=$(python3 - "$p" <<'PYL' 2>/dev/null
import json, sys, os
try:
    d = json.load(open(os.path.join(sys.argv[1], ".claude", "settings.json")))
except Exception:
    raise SystemExit(0)
out, off = [], 0
for k, v in (d.get("enabledPlugins") or {}).items():
    name, _, mk = k.partition("@")
    if mk != "maestro":
        continue
    out.append(("✔" if v else "✘") + name)
    off += 0 if v else 1
print(" ".join(sorted(out)))
print(off)
PYL
)
    PLUGS=$(echo "$LINE" | head -1)
    OFF=$(echo "$LINE" | tail -1)
    DIS_TOTAL=$((DIS_TOTAL + ${OFF:-0}))
    echo "  - $(basename "$p")  $PLUGS"
  done
  echo ""
  if [ "$DIS_TOTAL" -gt 0 ]; then
    warn "$DIS_TOTAL déclaration(s) à false — ces plugins sont installés mais inactifs."
    echo "     Les mettre à jour ne les activera pas. Pour en activer un :"
    echo "       cd <projet> && claude plugin enable <nom>@$MARKETPLACE --scope project"
  else
    ok "toutes les déclarations sont à true"
  fi
  exit 0
fi

echo -e "${B}Mise à jour vers $EXPECTED — ${#PROJECTS[@]} projet(s), dry-run=$DRY_RUN${N}"
DONE=0; FAILED=0
for P in "${PROJECTS[@]}"; do
  [ -d "$P" ] || { [ -d "$PROJECTS_ROOT/$P" ] && P="$PROJECTS_ROOT/$P"; }
  [ -d "$P" ] || { err "introuvable : $P"; FAILED=$((FAILED+1)); continue; }

  echo ""
  echo -e "${B}📦 $(basename "$P")${N}"
  PLUGINS=$(plugins_of "$P")
  [ -n "$PLUGINS" ] || { warn "aucun plugin @$MARKETPLACE déclaré — sauté"; continue; }

  # Un .claude/settings.json posé dans le home EST le fichier de scope user :
  # le mettre à jour en --scope project viserait le mauvais registre.
  SCOPE_ARG="project"
  if [ "$(cd "$P" && pwd -P)" = "$(cd "$HOME" && pwd -P)" ]; then
    SCOPE_ARG="user"
    warn "c'est ton dossier home → scope user (et non project)"
  fi

  PROJ_FAIL=0
  for PL in $PLUGINS; do
    act "claude plugin update $PL@$MARKETPLACE --scope $SCOPE_ARG"
    if [ "$DRY_RUN" = "0" ]; then
      if (cd "$P" && claude plugin update "$PL@$MARKETPLACE" --scope "$SCOPE_ARG" >/dev/null 2>&1); then
        ok "$PL"
      else
        err "$PL — échec"
        PROJ_FAIL=1
      fi
    fi
  done
  if [ "$PROJ_FAIL" = "0" ]; then DONE=$((DONE+1)); else FAILED=$((FAILED+1)); fi
done

echo ""
if [ "$DRY_RUN" = "1" ]; then
  echo -e "${B}Dry-run : ${#PROJECTS[@]} projet(s) seraient traités — RIEN n'a été mis à jour${N}"
else
  echo -e "${B}Terminé : $DONE ok, $FAILED en échec${N}"
fi
echo ""
echo "  Vérifier :  claude plugin list | grep -A1 '@$MARKETPLACE' | grep Version | sort -u"
echo "  Attendu  :  Version: $EXPECTED  (et plus aucun 5.3.x)"
echo ""
echo "  Pour que les prochaines versions se propagent seules :"
echo "     /plugin  → onglet Marketplaces → $MARKETPLACE → Enable auto-update"
echo "     (désactivé par défaut sur les marketplaces tierces)"
[ "$FAILED" = "0" ] || exit 1
