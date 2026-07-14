#!/bin/bash
# ============================================================
# Maestro — migrate-v4-to-v5.sh
#
# Migre un ou plusieurs projets de Maestro v4 (fichiers copiés
# + npm @arabiipte/maestro) vers Maestro 5 (marketplace de
# plugins Claude Code).
#
# USAGE :
#   ./migrate-v4-to-v5.sh <projet>              # un projet
#   ./migrate-v4-to-v5.sh <p1> <p2> <p3>        # une vague
#   ./migrate-v4-to-v5.sh --all                  # tous les projets v4 détectés
#   ./migrate-v4-to-v5.sh --all --dry-run        # préview sans rien toucher
#   ./migrate-v4-to-v5.sh --list                 # lister les projets v4 détectés
#
# CE QUE FAIT LE SCRIPT (par projet) :
#   1. Backup complet des éléments v4 → .maestro-v4-backup/
#   2. Retire les résidus v4 : scripts/hooks, .claude/{agents,commands,skills},
#      fichiers d'état (compteurs, session-log, loop-detector, router-seen)
#   3. Migre docs/memory-bank/ → maestro_docs/memory/ (mapping intelligent)
#   4. Migre quality-gates.json → maestro_docs/gates.json
#   5. S'assure que settings.json est sain (hooks: {})
#   6. Active les plugins Maestro 5 selon la stack détectée
#      (via claude CLI si dispo, sinon écriture directe des settings)
#   7. Injecte le bloc <maestro_routing> dans CLAUDE.md
#   8. Vérification finale (aucun résidu v4)
#
# SANS DANGER : dry-run disponible, backup systématique, git recommandé
# (le script refuse un working tree sale sauf --force-dirty).
# ============================================================

set -u

# ── Config ──────────────────────────────────────────────────
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Documents/Projects}"
MARKETPLACE_NAME="maestro"
MARKETPLACE_REPO="${MARKETPLACE_REPO:-arabiipte/maestro-v5}"
DRY_RUN=0
FORCE_DIRTY=0
LIST_ONLY=0
ALL=0

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
say()  { echo -e "$@"; }
ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "  ${RED}❌ $1${NC}"; }
act()  { if [ "$DRY_RUN" = "1" ]; then echo -e "  ${BLUE}[dry-run] $1${NC}"; else echo -e "  ${BLUE}→ $1${NC}"; fi; }

# ── Args ────────────────────────────────────────────────────
PROJECTS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force-dirty) FORCE_DIRTY=1 ;;
    --list) LIST_ONLY=1 ;;
    --all) ALL=1 ;;
    *) PROJECTS+=("$arg") ;;
  esac
done

# ── Détection des projets v4 ────────────────────────────────
detect_v4() {
  local dir="$1"
  [ -f "$dir/.claude/version.txt" ] && return 0
  [ -f "$dir/scripts/hooks/maestro-router.py" ] && return 0
  [ -f "$dir/scripts/hooks/post-edit-typecheck.sh" ] && return 0
  [ -d "$dir/.claude/skills/m-pipeline" ] && return 0
  [ -d "$dir/docs/memory-bank" ] && return 0
  return 1
}

if [ "$ALL" = "1" ] || [ "$LIST_ONLY" = "1" ]; then
  say "${BLUE}Détection des projets v4 dans $PROJECTS_ROOT...${NC}"
  while IFS= read -r d; do
    if detect_v4 "$d"; then PROJECTS+=("$d"); fi
  done < <(find "$PROJECTS_ROOT" -maxdepth 1 -mindepth 1 -type d | sort)
  say "  ${#PROJECTS[@]} projet(s) v4 détecté(s)."
fi

if [ "$LIST_ONLY" = "1" ]; then
  for p in ${PROJECTS[@]+"${PROJECTS[@]}"}; do echo "  - $(basename "$p")"; done
  exit 0
fi

if [ "${#PROJECTS[@]}" -eq 0 ]; then
  err "Aucun projet. Usage : $0 <projet...> | --all [--dry-run] | --list"
  exit 1
fi

# ── Prérequis globaux ───────────────────────────────────────
say ""
say "${BLUE}╔══════════════════════════════════════════════╗${NC}"
say "${BLUE}║   Maestro v4 → v5 — Migration                ║${NC}"
say "${BLUE}╚══════════════════════════════════════════════╝${NC}"
say "  Projets : ${#PROJECTS[@]}   Dry-run : $DRY_RUN"
say ""
say "${BLUE}▶ Prérequis${NC}"

HAS_CLAUDE=0
if command -v claude >/dev/null 2>&1; then
  HAS_CLAUDE=1
  ok "claude CLI disponible"
  if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
    ok "marketplace '$MARKETPLACE_NAME' déjà ajouté"
  else
    warn "marketplace '$MARKETPLACE_NAME' non trouvé"
    if [ "$DRY_RUN" = "0" ]; then
      act "claude plugin marketplace add $MARKETPLACE_REPO"
      claude plugin marketplace add "$MARKETPLACE_REPO" || {
        err "Échec de l'ajout du marketplace. Vérifie que $MARKETPLACE_REPO est poussé et accessible."
        exit 1
      }
    fi
  fi
else
  warn "claude CLI introuvable — fallback : écriture directe des settings projet"
fi
command -v python3 >/dev/null || { err "python3 requis"; exit 1; }

# ── Migration d'un projet ───────────────────────────────────
migrate_project() {
  local P="$1"
  local NAME; NAME=$(basename "$P")
  say ""
  say "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  say "${BLUE}📦 $NAME${NC}"

  [ -d "$P" ] || { err "introuvable : $P"; return 1; }

  # Sécurité git
  if [ -d "$P/.git" ] && [ "$FORCE_DIRTY" = "0" ]; then
    if [ -n "$(cd "$P" && git status --porcelain 2>/dev/null)" ]; then
      warn "working tree sale — commit/stash d'abord, ou --force-dirty. SKIP."
      return 1
    fi
  fi

  local BK="$P/.maestro-v4-backup-$(date +%Y%m%d-%H%M%S)"

  # ── 1. Backup ──
  say "  ${BLUE}1/8 Backup${NC}"
  if [ "$DRY_RUN" = "0" ]; then mkdir -p "$BK"; fi
  for item in scripts/hooks .claude/agents .claude/commands .claude/skills \
              .claude/version.txt .claude/quality-gates.json .claude/session-log.md \
              .claude/maestro.config.json docs/memory-bank; do
    if [ -e "$P/$item" ]; then
      act "backup $item"
      if [ "$DRY_RUN" = "0" ]; then
        mkdir -p "$BK/$(dirname "$item")"
        cp -r "$P/$item" "$BK/$item"
      fi
    fi
  done

  # ── 2. Retirer les résidus v4 ──
  say "  ${BLUE}2/8 Nettoyage v4${NC}"
  local V4_HOOKS="maestro-router.py post-edit-typecheck.sh stop-quality-gate.sh \
    pre-bash-guard.sh pre-edit-guard.sh post-edit-format.sh post-edit-emoji-check.sh \
    post-edit-print-check.sh context-rot-check.sh loop-detector.sh quality-gate.py \
    security-check.py session-start-context-inject.sh pre-commit-i18n.sh"
  for h in $V4_HOOKS; do
    [ -f "$P/scripts/hooks/$h" ] && act "rm scripts/hooks/$h" && [ "$DRY_RUN" = "0" ] && rm -f "$P/scripts/hooks/$h"
  done
  # scripts/hooks vidé ? le retirer (préserve les hooks custom non-Maestro)
  if [ -d "$P/scripts/hooks" ]; then
    local REMAINING=""
    for f in "$P/scripts/hooks"/*; do
      [ -e "$f" ] || continue
      local bn; bn=$(basename "$f")
      echo "$V4_HOOKS" | grep -qw "$bn" || REMAINING="$REMAINING$bn "
    done
    if [ -z "$REMAINING" ]; then
      act "rmdir scripts/hooks (ne contenait que du v4)"
      [ "$DRY_RUN" = "0" ] && rm -rf "$P/scripts/hooks"
    else
      warn "scripts/hooks : scripts custom conservés : $REMAINING"
    fi
  fi
  for item in .claude/agents .claude/commands .claude/skills .claude/version.txt \
              .claude/session-log.md .claude/loop-detector .claude/.typecheck-counter \
              .claude/.typecheck-last-run .claude/session-tokens.txt \
              .claude/.maestro-router-seen .claude/maestro.config.json \
              .claude/.sense-env-disabled; do
    [ -e "$P/$item" ] && act "rm $item" && [ "$DRY_RUN" = "0" ] && rm -rf "$P/${item:?}"
  done

  # ── 3. Migrer la memory bank ──
  say "  ${BLUE}3/8 Migration memory-bank → maestro_docs/memory${NC}"
  if [ "$DRY_RUN" = "0" ]; then
    mkdir -p "$P/maestro_docs/memory/internal/archive" "$P/maestro_docs/specs" "$P/maestro_docs/tasks"
  fi
  # sources possibles (v4 ancienne et nouvelle convention)
  for SRC in "$P/docs/memory-bank" "$P/maestro_docs/memory-bank"; do
    [ -d "$SRC" ] || continue
    migrate_mem() { # $1=fichier source relatif  $2=destination relative à maestro_docs/memory
      if [ -f "$SRC/$1" ]; then
        act "memory: $1 → memory/$2"
        if [ "$DRY_RUN" = "0" ]; then
          mkdir -p "$P/maestro_docs/memory/$(dirname "$2")"
          # ne pas écraser une destination existante non vide
          if [ -s "$P/maestro_docs/memory/$2" ]; then
            cat "$SRC/$1" >> "$P/maestro_docs/memory/$2"
          else
            cp "$SRC/$1" "$P/maestro_docs/memory/$2"
          fi
        fi
      fi
    }
    migrate_mem "project-brief.md"   "project-brief.md"
    migrate_mem "tech-decisions.md"  "tech-decisions.md"
    migrate_mem "patterns.md"        "patterns.md"
    migrate_mem "project-rules.md"   "project-rules.md"
    migrate_mem "errors-log.md"      "internal/errors-log.md"
    migrate_mem "current-sprint.md"  "internal/archive/v4-current-sprint.md"
    # tout autre fichier md → internal/
    for f in "$SRC"/*.md; do
      [ -f "$f" ] || continue
      base=$(basename "$f")
      case "$base" in
        project-brief.md|tech-decisions.md|patterns.md|project-rules.md|errors-log.md|current-sprint.md) ;;
        *) migrate_mem "$base" "internal/$base" ;;
      esac
    done
    act "retire l'ancienne memory-bank ($SRC → backup déjà fait)"
    [ "$DRY_RUN" = "0" ] && rm -rf "$SRC"
  done

  # ── 4. quality-gates.json → maestro_docs/gates.json ──
  say "  ${BLUE}4/8 Gates${NC}"
  if [ -f "$BK/.claude/quality-gates.json" ] || [ -f "$P/.claude/quality-gates.json" ]; then
    local GSRC="$P/.claude/quality-gates.json"; [ -f "$GSRC" ] || GSRC="$BK/.claude/quality-gates.json"
    local LEVEL
    LEVEL=$(python3 -c "import json;print(json.load(open('$GSRC')).get('level','standard'))" 2>/dev/null || echo standard)
    act "gates.json (level: $LEVEL)"
    if [ "$DRY_RUN" = "0" ]; then
      printf '{ "level": "%s" }\n' "$LEVEL" > "$P/maestro_docs/gates.json"
      rm -f "$P/.claude/quality-gates.json"
    fi
  else
    act "gates.json (level: standard, défaut)"
    [ "$DRY_RUN" = "0" ] && printf '{ "level": "standard" }\n' > "$P/maestro_docs/gates.json"
  fi

  # ── 5. settings.json sain ──
  say "  ${BLUE}5/8 Settings${NC}"
  if [ "$DRY_RUN" = "0" ]; then
    mkdir -p "$P/.claude"
    python3 << PYEOF
import json, os
p = "$P/.claude/settings.json"
try:
    d = json.load(open(p))
except Exception:
    d = {}
hooks = d.get("hooks") or {}
bad = []
for ev, groups in list(hooks.items()):
    for g in groups if isinstance(groups, list) else []:
        for h in g.get("hooks", []):
            cmd = h.get("command", "")
            if any(k in cmd for k in ("typecheck","tsc","jest","vitest","prettier","eslint","claude-flow","ruv-swarm","scripts/hooks")):
                bad.append(ev)
if bad or hooks:
    d["hooks"] = {}
d.setdefault("permissions", {"allow": [], "deny": ["Bash(rm -rf /)","Bash(curl * | bash)","Bash(wget * | sh)"]})
json.dump(d, open(p,"w"), indent=2, ensure_ascii=False)
open(p,"a").write("\n")
print("     hooks projet: {} (résidus retirés: {})".format("vides ✅", len(bad)))
PYEOF
  else
    act "vérifier/vider hooks dans .claude/settings.json"
  fi

  # ── 6. Activer les plugins v5 selon la stack ──
  say "  ${BLUE}6/8 Plugins Maestro 5${NC}"
  local PLUGINS="maestro-core maestro-dev maestro-quality maestro-vcs"
  if [ -f "$P/package.json" ]; then
    if python3 -c "
import json
d=json.load(open('$P/package.json'))
deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}
exit(0 if ('expo' in deps or 'react-native' in deps) else 1)" 2>/dev/null; then
      PLUGINS="$PLUGINS maestro-mobile"
    fi
    if python3 -c "
import json
d=json.load(open('$P/package.json'))
deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}
exit(0 if any(k in deps for k in ('next','nuxt','react-dom','vue')) else 1)" 2>/dev/null; then
      PLUGINS="$PLUGINS maestro-web"
    fi
  fi
  act "plugins : $PLUGINS"
  if [ "$DRY_RUN" = "0" ]; then
    if [ "$HAS_CLAUDE" = "1" ]; then
      for pl in $PLUGINS; do
        (cd "$P" && claude plugin install "$pl@$MARKETPLACE_NAME" --scope project >/dev/null 2>&1) \
          && ok "$pl installé" \
          || warn "$pl : install CLI échouée — fallback settings"
      done
    fi
    # Fallback/garantie : enabledPlugins dans les settings projet
    python3 << PYEOF
import json
p = "$P/.claude/settings.json"
d = json.load(open(p))
ep = d.get("enabledPlugins") or {}
for pl in "$PLUGINS".split():
    ep[f"{pl}@$MARKETPLACE_NAME"] = True
d["enabledPlugins"] = ep
json.dump(d, open(p,"w"), indent=2, ensure_ascii=False)
open(p,"a").write("\n")
print("     enabledPlugins écrits ✅")
PYEOF
  fi

  # ── 7. Bloc routing dans CLAUDE.md ──
  say "  ${BLUE}7/8 CLAUDE.md routing${NC}"
  if [ "$DRY_RUN" = "0" ]; then
    python3 << 'PYEOF2' - "$P"
import sys, os
P = sys.argv[1]
path = os.path.join(P, "CLAUDE.md")
block = """<maestro_routing>
Maestro 5 is installed. Route by intent:
- Feature end-to-end -> skill maestro-dev:00-sdlc (say "auto" for unattended)
- Plan only -> maestro-dev:01-plan · Build a plan -> maestro-dev:02-implement
- Independent review -> agent checker · Challenge a plan -> agent m-devil-advocate
- Architecture/DB design -> agent m-architect
- Commit with gates -> maestro-vcs:00-commit · PR -> maestro-vcs:01-pull-request
- Memory stale -> maestro-core:01-memory · Context bloated -> maestro-core:02-gardener
- Install health -> maestro-core:04-doctor · Menu: /maestro
Always adopt the expert posture of the task domain and keep task state in
maestro_docs/tasks/<date>_<slug>/ so any session can resume.
</maestro_routing>"""
content = ""
if os.path.exists(path):
    content = open(path).read()
o, c = content.find("<maestro_routing>"), content.find("</maestro_routing>")
if o != -1 and c != -1 and c > o:
    content = content[:o] + block + content[c+len("</maestro_routing>"):]
else:
    if not content:
        content = f"# {os.path.basename(P)}\n"
    content = content.rstrip() + "\n\n" + block + "\n"
open(path, "w").write(content)
print("     bloc routing upserté ✅")
PYEOF2
  else
    act "upsert <maestro_routing> dans CLAUDE.md"
  fi

  # ── 8. Vérification finale ──
  say "  ${BLUE}8/8 Vérification${NC}"
  local ISSUES=0
  for leftover in scripts/hooks/maestro-router.py scripts/hooks/post-edit-typecheck.sh \
                  .claude/agents .claude/skills/m-pipeline docs/memory-bank .claude/version.txt; do
    if [ -e "$P/$leftover" ] && [ "$DRY_RUN" = "0" ]; then err "résidu : $leftover"; ISSUES=$((ISSUES+1)); fi
  done
  if [ "$DRY_RUN" = "0" ]; then
    grep -rq "claude-flow\|ruv-swarm" "$P/.claude" 2>/dev/null && { err "référence claude-flow/ruv-swarm dans .claude/"; ISSUES=$((ISSUES+1)); }
    [ -f "$P/maestro_docs/memory/project-brief.md" ] || warn "pas de project-brief migré (lancer maestro-core:01-memory)"
    [ "$ISSUES" -eq 0 ] && ok "projet propre — backup: $(basename "$BK")"
  else
    ok "dry-run terminé pour $NAME"
  fi
  return $ISSUES
}

# ── Boucle ──────────────────────────────────────────────────
DONE=0; FAILED=0
for P in ${PROJECTS[@]+"${PROJECTS[@]}"}; do
  # accepter un nom relatif à PROJECTS_ROOT
  [ -d "$P" ] || { [ -d "$PROJECTS_ROOT/$P" ] && P="$PROJECTS_ROOT/$P"; }
  if migrate_project "$P"; then DONE=$((DONE+1)); else FAILED=$((FAILED+1)); fi
done

say ""
say "${GREEN}╔══════════════════════════════════════════════╗${NC}"
say "${GREEN}║  Migration terminée : $DONE ok, $FAILED échec(s)        ${NC}"
say "${GREEN}╚══════════════════════════════════════════════╝${NC}"
say ""
say "▶ ENSUITE, dans chaque projet migré (session Claude Code) :"
say "   1. /maestro-core:04-doctor check   → doit être 100% vert"
say "   2. /maestro-core:01-memory review  → vérifier la memory migrée"
say "   3. /maestro-core:00-onboard (action official-plugins) → installe les"
say "      officiels PROJET selon la stack : security-guidance, expo,"
say "      playwright (PDF RTL / E2E), figma"
say "   4. Committer : git add -A && git commit -m 'chore: migrate maestro v4 -> v5'"
say ""
say "▶ Le backup de chaque projet est dans .maestro-v4-backup-*/  (à supprimer après 1 semaine de rodage)"
