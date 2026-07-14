#!/bin/bash
# ============================================================
# Maestro 5 — setup-all.sh : LE script maître
#
# Fait tout, dans l'ordre, avec confirmation à chaque phase :
#
#   PHASE 1  Publier le repo sur GitHub (arabiipte/maestro-v5)
#   PHASE 2  Publier le package npm @arabiipte/maestro@5.x (GitHub Packages)
#   PHASE 3  Déprécier la v4 sur npm (optionnel)
#   PHASE 4  Setup global : marketplace + plugins officiels (scope user)
#            + désinstallation du npm v4 global
#   PHASE 5  Migration des projets (~/Documents/Projects)
#            → pilotes d'abord, ou tout d'un coup
#
# À lancer DEPUIS la racine du repo maestro v5 :
#   cd ~/Documents/maestro-v5-work/maestro && ./scripts/setup-all.sh
#
# Prérequis :
#   - git configuré (user chakerben)
#   - gh CLI authentifié (gh auth login) OU repo créé à la main
#   - Token GitHub Packages dans ~/.npmrc (déjà en place si tu
#     publiais la v4) : //npm.pkg.github.com/:_authToken=ghp_xxx
# ============================================================

set -u

ORG="arabiipte"
REPO="maestro-v5"
PKG="@arabiipte/maestro"
VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "5.3.0")
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Documents/Projects}"

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "  ${RED}❌ $1${NC}"; }
step() { echo -e "\n${BLUE}════════ $1 ════════${NC}"; }
ask()  { read -p "▶️  $1 (o/N) " r; [[ "$r" =~ ^[oOyY]$ ]]; }

# ── Garde-fous ──────────────────────────────────────────────
[ -f ".claude-plugin/marketplace.json" ] || { err "Lance ce script depuis la racine du repo maestro v5."; exit 1; }
command -v node >/dev/null || { err "node requis"; exit 1; }
command -v git  >/dev/null || { err "git requis"; exit 1; }

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Maestro 5 — Setup complet ($VERSION)         ${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"

# Validation avant tout
step "Validation du framework"
node scripts/validate.js >/dev/null 2>&1 && ok "validate.js : all checks passed" || { err "validate.js échoue — corrige avant de publier"; exit 1; }
bash scripts/tests/bash-guard.test.sh >/dev/null 2>&1 && ok "bash-guard : 34/34 tests" || { err "tests bash-guard échouent"; exit 1; }

# ══════════════════════════════════════════════════════════
step "PHASE 1 — Publication GitHub ($ORG/$REPO)"
# ══════════════════════════════════════════════════════════
if ask "Publier sur GitHub ?"; then
  # git init si nécessaire
  if [ ! -d ".git" ]; then
    git init
    git add -A
    git commit -m "feat: maestro $VERSION — complete framework"
    ok "repo git initialisé"
  else
    if [ -n "$(git status --porcelain)" ]; then
      git add -A && git commit -m "feat: maestro $VERSION"
      ok "changements committés"
    else
      ok "working tree propre"
    fi
  fi

  # remote + push
  if git remote get-url origin >/dev/null 2>&1; then
    ok "remote origin déjà configuré : $(git remote get-url origin)"
  elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "  Création du repo via gh CLI..."
    gh repo create "$ORG/$REPO" --private --source . --remote origin 2>/dev/null \
      && ok "repo $ORG/$REPO créé" \
      || { git remote add origin "git@github.com:$ORG/$REPO.git"; warn "repo existait peut-être déjà — remote ajouté"; }
  else
    git remote add origin "git@github.com:$ORG/$REPO.git"
    warn "gh CLI absent — crée le repo $ORG/$REPO sur github.com si pas déjà fait"
  fi

  git branch -M main
  git push -u origin main && ok "poussé sur main" || { err "push échoué — vérifie le repo/l'accès SSH"; exit 1; }

  # tag de version (déclenche publish.yml → npm)
  if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    warn "tag v$VERSION existe déjà"
  else
    git tag -a "v$VERSION" -m "Maestro $VERSION"
    git push origin "v$VERSION" && ok "tag v$VERSION poussé (déclenche la publication npm en CI)"
  fi
else
  warn "Phase 1 sautée"
fi

# ══════════════════════════════════════════════════════════
step "PHASE 2 — Publication npm $PKG@$VERSION (GitHub Packages)"
# ══════════════════════════════════════════════════════════
echo "  Note : le tag v$VERSION déclenche déjà publish.yml en CI."
echo "  Cette phase publie EN LOCAL (utile si tu ne veux pas attendre la CI)."
if ask "Publier depuis cette machine ?"; then
  if grep -q "npm.pkg.github.com" ~/.npmrc 2>/dev/null; then
    ok "token GitHub Packages trouvé dans ~/.npmrc"
    npm publish && ok "$PKG@$VERSION publié" || warn "publication échouée (déjà publié par la CI ? version existante ?)"
  else
    warn "Pas de token dans ~/.npmrc. Ajoute :"
    echo "     echo '//npm.pkg.github.com/:_authToken=TON_TOKEN_ghp' >> ~/.npmrc"
    echo "     (token avec scope write:packages)  — puis relance cette phase avec : npm publish"
  fi
else
  warn "Phase 2 sautée (la CI publiera via le tag)"
fi

# ══════════════════════════════════════════════════════════
step "PHASE 3 — Déprécier la v4 sur npm (optionnel)"
# ══════════════════════════════════════════════════════════
if ask "Déprécier $PKG@4.x ?"; then
  npm deprecate --registry=https://npm.pkg.github.com "$PKG@<5.0.0" \
    "Maestro v4 is replaced by the v5 plugin marketplace: claude plugin marketplace add $ORG/$REPO" \
    && ok "v4 dépréciée" || warn "dépréciation échouée (droits/registry ?) — pas bloquant"
else
  warn "Phase 3 sautée"
fi

# ══════════════════════════════════════════════════════════
step "PHASE 4 — Setup global de la machine"
# ══════════════════════════════════════════════════════════
if ask "Configurer le marketplace + plugins officiels (scope user) ?"; then
  if command -v claude >/dev/null 2>&1; then
    # marketplace v5
    claude plugin marketplace add "$ORG/$REPO" 2>/dev/null && ok "marketplace 'maestro' ajouté" || warn "marketplace déjà présent ou erreur"

    # npm v4 global : dehors
    if npm ls -g "$PKG" >/dev/null 2>&1; then
      npm uninstall -g "$PKG" && ok "npm v4 global désinstallé"
    else
      ok "pas de npm v4 global"
    fi

    # plugins officiels — scope user (matrice onboard 5.3.0)
    for p in typescript-lsp commit-commands github context7 frontend-design code-review pr-review-toolkit; do
      claude plugin install "$p@claude-plugins-official" --scope user >/dev/null 2>&1 \
        && ok "officiel: $p" || warn "officiel: $p (déjà installé ou erreur)"
    done

    # Python dans certains projets ?
    if ask "Tu utilises Python dans certains projets — installer pyright-lsp ?"; then
      claude plugin install "pyright-lsp@claude-plugins-official" --scope user >/dev/null 2>&1 \
        && ok "officiel: pyright-lsp" || warn "pyright-lsp (déjà installé ou erreur)"
      command -v pyright >/dev/null 2>&1 || warn "binaire manquant → pipx install pyright (ou npm i -g pyright)"
    fi
    echo "  ℹ️  Plugins officiels PAR PROJET (security-guidance, expo, playwright, figma) :"
    echo "     proposés par /maestro-core:00-onboard dans chaque projet."

    # binaire LSP
    if command -v typescript-language-server >/dev/null 2>&1; then
      ok "typescript-language-server présent"
    else
      warn "binaire LSP manquant → npm i -g typescript typescript-language-server"
      if ask "L'installer maintenant ?"; then
        npm i -g typescript typescript-language-server && ok "LSP installé"
      fi
    fi
  else
    err "claude CLI introuvable — installe Claude Code d'abord"
  fi
else
  warn "Phase 4 sautée"
fi

# ══════════════════════════════════════════════════════════
step "PHASE 5 — Migration des projets ($PROJECTS_ROOT)"
# ══════════════════════════════════════════════════════════
MIGRATE="./scripts/migrate-v4-to-v5.sh"
[ -x "$MIGRATE" ] || chmod +x "$MIGRATE"

echo "  Projets v4 détectés :"
"$MIGRATE" --list | sed 's/^/  /'
echo ""
echo "  Stratégie recommandée : 3 pilotes → rodage 1 semaine → le reste."
echo "  1) Pilotes (tu donnes les noms)"
echo "  2) TOUT migrer maintenant"
echo "  3) Dry-run global (préview)"
echo "  4) Sauter"
read -p "▶️  Choix (1/2/3/4) : " choice
case "$choice" in
  1)
    read -p "  Noms des projets pilotes (séparés par des espaces) : " pilots
    # shellcheck disable=SC2086
    "$MIGRATE" $pilots
    ;;
  2)
    if ask "Confirmer la migration de TOUS les projets (backup automatique par projet)"; then
      "$MIGRATE" --all
    fi
    ;;
  3) "$MIGRATE" --all --dry-run ;;
  *) warn "Phase 5 sautée — relance plus tard : $MIGRATE --all" ;;
esac

# ══════════════════════════════════════════════════════════
step "TERMINÉ"
# ══════════════════════════════════════════════════════════
echo "  Dans chaque projet migré (session Claude Code) :"
echo "    /maestro-core:04-doctor check     → doit être vert"
echo "    git add -A && git commit -m 'chore: migrate maestro v4 -> v5'"
echo ""
echo "  Surveillance semaine 1 : nodels → AUCUN tsc/jest/claude-flow fantôme."
echo "  Cleanup semaine 3      : rm -rf <projet>/.maestro-v4-backup-*"
