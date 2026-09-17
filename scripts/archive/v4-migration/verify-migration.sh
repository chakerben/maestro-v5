#!/bin/bash
# ============================================================
# verify-migration.sh — doctor batch post-migration Maestro 5
# Exécute les checks de maestro-core:04-doctor sur TOUS les
# projets d'un coup, sans ouvrir de session Claude Code.
#   🔴 contrebande v4 (hooks scripts, hooks toxiques, claude-flow)
#   🟠 structure v5 incomplète
#   🟢 projet sain
# Usage : ./verify-migration.sh   [PROJECTS_ROOT=... pour changer]
# ============================================================
set -u
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Documents/Projects}"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

CLEAN=0; WARN=0; CRIT=0; SKIPPED=0
CRIT_LIST=""; WARN_LIST=""

V4_HOOKS="maestro-router.py post-edit-typecheck.sh stop-quality-gate.sh pre-bash-guard.sh pre-edit-guard.sh post-edit-format.sh post-edit-emoji-check.sh post-edit-print-check.sh context-rot-check.sh loop-detector.sh quality-gate.py security-check.py session-start-context-inject.sh pre-commit-i18n.sh"

echo -e "${BLUE}🩺 Doctor batch — $PROJECTS_ROOT${NC}\n"
printf "%-32s %s\n" "PROJET" "VERDICT"
printf "%-32s %s\n" "──────" "───────"

for P in "$PROJECTS_ROOT"/*/; do
  NAME=$(basename "$P")
  # Ignorer les non-projets
  [ -d "$P/.claude" ] || [ -f "$P/package.json" ] || [ -f "$P/pubspec.yaml" ] || { SKIPPED=$((SKIPPED+1)); continue; }

  ISSUES=""

  # ── 🔴 Contrebande v4 ──
  for h in $V4_HOOKS; do
    [ -f "$P/scripts/hooks/$h" ] && ISSUES="$ISSUES CRIT:hook-v4($h)"
  done
  if [ -f "$P/.claude/settings.json" ]; then
    grep -qE '"command"[^"]*"[^"]*(typecheck|tsc |jest|vitest|prettier|eslint|claude-flow|ruv-swarm|scripts/hooks)' "$P/.claude/settings.json" 2>/dev/null \
      && ISSUES="$ISSUES CRIT:hook-toxique-settings"
  fi
  # refs vives claude-flow (hors backups)
  if find "$P/.claude" "$P/.mcp.json" -maxdepth 1 -type f 2>/dev/null | grep -q .; then
    FLOW=$(find "$P" -maxdepth 2 \( -path "*/.claude/*.json" -o -name ".mcp.json" \) -not -path "*backup*" \
      -exec grep -l "claude-flow\|ruv-swarm" {} + 2>/dev/null || true)
    [ -n "$FLOW" ] && ISSUES="$ISSUES CRIT:claude-flow-ref"
  fi
  # anciens artefacts v4
  [ -d "$P/docs/memory-bank" ] && ISSUES="$ISSUES CRIT:memory-bank-v4"
  [ -f "$P/.claude/version.txt" ] && ISSUES="$ISSUES CRIT:version-v4"
  [ -d "$P/.claude/agents" ] && ISSUES="$ISSUES CRIT:agents-v4"
  [ -d "$P/.claude/skills" ] && ISSUES="$ISSUES CRIT:skills-v4"

  # ── 🟠 Structure v5 ──
  [ -d "$P/maestro_docs/memory" ] || ISSUES="$ISSUES WARN:maestro_docs-absent"
  [ -f "$P/maestro_docs/gates.json" ] || ISSUES="$ISSUES WARN:gates-absent"
  if [ -f "$P/CLAUDE.md" ]; then
    grep -q "maestro_routing" "$P/CLAUDE.md" || ISSUES="$ISSUES WARN:routing-absent"
  else
    ISSUES="$ISSUES WARN:CLAUDE.md-absent"
  fi
  if [ -f "$P/.claude/settings.json" ]; then
    grep -q "maestro-core@maestro" "$P/.claude/settings.json" || ISSUES="$ISSUES WARN:plugins-non-actives"
  else
    ISSUES="$ISSUES WARN:settings-absent"
  fi

  # ── Verdict ──
  if echo "$ISSUES" | grep -q "CRIT:"; then
    printf "%-32s ${RED}🔴 %s${NC}\n" "$NAME" "$(echo $ISSUES | tr ' ' '\n' | grep CRIT | sed 's/CRIT://' | tr '\n' ' ')"
    CRIT=$((CRIT+1)); CRIT_LIST="$CRIT_LIST $NAME"
  elif [ -n "$ISSUES" ]; then
    printf "%-32s ${YELLOW}🟠 %s${NC}\n" "$NAME" "$(echo $ISSUES | tr ' ' '\n' | grep WARN | sed 's/WARN://' | tr '\n' ' ')"
    WARN=$((WARN+1)); WARN_LIST="$WARN_LIST $NAME"
  else
    printf "%-32s ${GREEN}🟢 sain${NC}\n" "$NAME"
    CLEAN=$((CLEAN+1))
  fi
done

echo ""
echo -e "${BLUE}════════ BILAN ════════${NC}"
echo -e "  ${GREEN}🟢 sains    : $CLEAN${NC}"
echo -e "  ${YELLOW}🟠 warnings : $WARN${NC}${WARN_LIST:+  →$WARN_LIST}"
echo -e "  ${RED}🔴 critiques: $CRIT${NC}${CRIT_LIST:+  →$CRIT_LIST}"
echo -e "  ⚪ ignorés (non-projets) : $SKIPPED"
echo ""
if [ "$CRIT" -gt 0 ]; then
  echo -e "${RED}▶ Pour chaque 🔴 : relancer ./scripts/migrate-v4-to-v5.sh <projet> (idempotent)${NC}"
fi
if [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}▶ Les 🟠 'plugins-non-actives' ou 'routing-absent' = projet pas encore migré (normal si volontaire)${NC}"
fi
[ "$CRIT" -eq 0 ] && echo -e "${GREEN}✅ AUCUNE contrebande v4 — la promesse zéro-crash tient.${NC}"
