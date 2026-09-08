#!/bin/bash
# ============================================================
# Maestro 5 — install-shortcuts.sh
# Crée des commandes COURTES personnelles (~/.claude/commands/)
# qui délèguent aux skills Maestro. Sans préfixe de plugin,
# disponibles dans tous les projets.
#
#   /menu     → carte des capacités        /onboard  → setup projet
#   /sdlc     → pipeline complet           /auto     → pipeline non-supervisé
#   /plan     → planifier                  /impl     → exécuter un plan
#   /check    → doctor (santé projet)      /garden   → dégraisser le contexte
#   /mem      → régénérer la memory        /gates    → niveau de gate qualité
#   /ship     → commit gated + secrets     /pr       → pull request
#   /release  → release semver             /sec      → audit sécurité
#   /perf     → audit performance          /design   → design review
#   /rtl      → audit RTL/arabe            /prd      → PRD
#   /stories  → user stories               /specs    → spec technique
#   /wt       → worktree (une branche = un répertoire)
#
# Installe aussi la commande `gwt` dans ~/.local/bin (lien vers scripts/gwt) :
# c'est l'outil du skill maestro-vcs:03-worktree.
#
# NB: /doctor /memory /review sont des built-ins Claude Code
#     → d'où /check /mem /design ici.
# Relance ta session Claude Code après installation.
# ============================================================
set -u
DIR="$HOME/.claude/commands"
mkdir -p "$DIR"

mk() { # $1=nom  $2=skill cible  $3=description  $4=hint
cat > "$DIR/$1.md" << EOF
---
description: $3
argument-hint: "$4"
---

Use the Maestro skill \`$2\` to handle this request: \$ARGUMENTS

Follow the skill's SKILL.md contract exactly (read it first), including its
actions table and transversal rules.
EOF
echo "  ✅ /$1  →  $2"
}

echo "📦 Installation des raccourcis Maestro dans $DIR"
mk menu    "maestro-core menu command (commands/maestro.md)" "Show the Maestro capability map grouped by intent" ""
mk onboard "maestro-core:00-onboard"   "Onboard this project into Maestro 5 (stack detection, plugins, memory)" ""
mk sdlc    "maestro-dev:00-sdlc"       "Full pipeline: spec → plan → implement → review → ship" "<feature>"
mk auto    "maestro-dev:00-sdlc"       "Full pipeline UNATTENDED (auto mode, hard stops only)" "<feature>"
mk plan    "maestro-dev:01-plan"       "Turn a request/spec into a phased, resumable plan" "<request or spec path>"
mk impl    "maestro-dev:02-implement"  "Execute an existing plan phase by phase (resumes automatically)" "<plan path>"
mk check   "maestro-core:04-doctor"    "Project health check: contraband, structure, drift" "check | fix"
mk garden  "maestro-core:02-gardener"  "Context anti-bloat: measure, archive, contradictions" "measure | archive | contradictions"
mk mem     "maestro-core:01-memory"    "Generate/review project memory from the real codebase" "generate | review | sync"
mk gates   "maestro-quality:00-quality-gate" "Quality gate level (off/standard/high/paranoid)" "status | set <level> | run"
mk ship    "maestro-vcs:00-commit"     "Commit through the quality gate + secret scan" "[scope hint]"
mk pr      "maestro-vcs:01-pull-request" "Open a structured PR from the task folder" "[draft]"
mk wt      "maestro-vcs:03-worktree"   "Isolate a branch in its own git worktree (sessions concurrentes)" "new <branche> | list | remove <branche>"
mk release "maestro-vcs:02-release"    "Cut a release: semver bump + changelog + tag" "major | minor | patch"
mk sec     "maestro-quality:01-security-audit" "Deep OWASP-aligned security audit" "[scope path]"
mk perf    "maestro-quality:02-perf-audit"     "Measure-first performance audit" "[scope path]"
mk design  "maestro-web:02-design-review"      "Scored design review: states, a11y, RTL, visual" "<path, screenshot or URL>"
mk rtl     "maestro-mobile:01-rtl-i18n"        "Arabic/RTL correctness audit (web AND mobile)" "audit [scope]"
mk prd     "maestro-pm:00-prd"         "Product Requirements Document (FR/EN/AR)" "<product idea>"
mk stories "maestro-pm:01-user-stories" "User stories with Given/When/Then criteria" "<PRD path or feature>"
mk specs   "maestro-pm:02-specs"       "Technical spec: contracts, schema, NFRs" "<story path or feature>"

# /auto force le mode auto explicitement
cat > "$DIR/auto.md" << 'EOF'
---
description: Full pipeline UNATTENDED (auto mode, hard stops only)
argument-hint: "<feature>"
---

Use the Maestro skill `maestro-dev:00-sdlc` in **auto mode** for: $ARGUMENTS

Auto mode rules apply: no pauses, devil-advocate replaces human approval on
the plan, hard stops on blocked/gate-red-x3/payment-destructive/credentials,
open the PR but NEVER merge. Read the skill's SKILL.md first.
EOF

echo ""
echo "✅ $(ls "$DIR" | wc -l | tr -d ' ') commandes installées."
echo "▶ Relance ta session Claude Code, puis tape / pour voir la liste."
echo "▶ Désinstallation d'un raccourci : rm ~/.claude/commands/<nom>.md"

# ── gwt : l'outil du skill maestro-vcs:03-worktree ─────────────────────────
# Un lien, pas une copie : une mise à jour du marketplace met l'outil à jour.
BIN_SRC="$(cd "$(dirname "$0")" && pwd)/gwt"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
chmod +x "$BIN_SRC"
ln -sfn "$BIN_SRC" "$BIN_DIR/gwt"
echo "  ✅ gwt   →  $BIN_SRC"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  ⚠️  $BIN_DIR absent du PATH — ajoute : export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
git config --global alias.wt '!gwt' 2>/dev/null && echo "  ✅ alias git wt  →  gwt"
