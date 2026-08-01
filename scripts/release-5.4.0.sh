#!/bin/bash
# ============================================================
# Maestro — release-5.4.0.sh
#
# Publie la 5.4.0 sur chakerben/maestro-v5 et prépare la machine.
# Script à usage unique : à supprimer une fois la release passée.
#
# USAGE :
#   ./scripts/release-5.4.0.sh --dry-run    # montre tout, ne touche à rien
#   ./scripts/release-5.4.0.sh              # exécute, avec confirmation par phase
#
# PRINCIPES (les mêmes que ceux que l'audit reprochait aux scripts existants) :
#   - set -euo pipefail : une erreur arrête tout, pas de demi-release silencieuse
#   - option inconnue = exit 2, jamais interprétée comme autre chose
#   - --dry-run ne mute rien, y compris ~/.npmrc
#   - confirmation avant chaque phase qui écrit ou pousse
#   - idempotent : relançable après un échec, il reprend où il en est
#   - aucune commande destructive (pas de rm -rf, pas de branch -M, pas de force)
# ============================================================

set -euo pipefail

NEW_OWNER="chakerben"
REPO="maestro-v5"
NEW_URL="https://github.com/${NEW_OWNER}/${REPO}.git"
VERSION="5.4.0"
TAG="v${VERSION}"
SCOPE="@${NEW_OWNER}"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "option inconnue : $arg (--dry-run)" >&2; exit 2 ;;
    *)  echo "argument inattendu : $arg" >&2; exit 2 ;;
  esac
done

B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
step() { echo -e "\n${B}▶ $1${NC:-$N}"; }
ok()   { echo -e "  ${G}✅ $1${N}"; }
warn() { echo -e "  ${Y}⚠️  $1${N}"; }
err()  { echo -e "  ${R}❌ $1${N}"; }
act()  { if [ "$DRY_RUN" = "1" ]; then echo -e "  ${B}[dry-run] $1${N}"; else echo -e "  ${B}→ $1${N}"; fi; }
ask()  {
  [ "$DRY_RUN" = "1" ] && { echo -e "  ${B}[dry-run] (confirmation sautée) $1${N}"; return 1; }
  local r=""; read -r -p "  $1 [o/N] " r || r=""
  [[ "$r" =~ ^[oOyY]$ ]]
}

cd "$(dirname "$0")/.."
ROOT=$(pwd)
echo -e "${B}╔══════════════════════════════════════════════╗${N}"
echo -e "${B}║   Maestro ${VERSION} → ${NEW_OWNER}/${REPO}          ║${N}"
echo -e "${B}╚══════════════════════════════════════════════╝${N}"
echo "  Dépôt   : $ROOT"
echo "  Dry-run : $DRY_RUN"

# ── 0. Préflight ────────────────────────────────────────────
step "0/6 Préflight"

[ -f "$ROOT/.claude-plugin/marketplace.json" ] || { err "pas le dépôt maestro"; exit 1; }
ok "dépôt reconnu"

# Verrou git résiduel : sûr à retirer si aucun git ne tourne.
if [ -f "$ROOT/.git/index.lock" ]; then
  if pgrep -x git >/dev/null 2>&1; then
    err "un process git tourne — ferme-le avant de continuer"; exit 1
  fi
  act "rm .git/index.lock (verrou résiduel, aucun git en cours)"
  if [ "$DRY_RUN" = "0" ]; then
    rm -f "$ROOT/.git/index.lock"
    ok "verrou retiré"
  else
    warn "verrou TOUJOURS présent (dry-run) — git refusera de committer tant qu'il est là"
  fi
else
  ok "pas de verrou git"
fi

PKG_VERSION=$(node -p "require('$ROOT/package.json').version")
[ "$PKG_VERSION" = "$VERSION" ] || { err "package.json dit $PKG_VERSION, attendu $VERSION"; exit 1; }
ok "package.json en $VERSION"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  warn "le tag $TAG existe déjà localement — la phase 4 sera sautée"
fi

step "0b/6 Tests"
act "npm test"
if [ "$DRY_RUN" = "0" ]; then
  npm test >/tmp/maestro-release-test.log 2>&1 || { err "npm test ROUGE — voir /tmp/maestro-release-test.log"; tail -20 /tmp/maestro-release-test.log; exit 1; }
  ok "tests verts (versions + validate + bash-guard + memory-sync)"
else
  warn "tests NON exécutés (dry-run)"
fi

# ── 1. Commit ───────────────────────────────────────────────
step "1/6 Commit"
if [ -z "$(git status --porcelain)" ]; then
  ok "rien à committer (déjà fait ?)"
else
  git status --short | sed 's/^/     /'
  if [ -f "$ROOT/MAESTRO-CONTEXT-HANDOFF.md" ] && ! git ls-files --error-unmatch MAESTRO-CONTEXT-HANDOFF.md >/dev/null 2>&1; then
    warn "MAESTRO-CONTEXT-HANDOFF.md est un document personnel encore non versionné."
    if ask "L'exclure du dépôt public (ajout à .gitignore) ?"; then
      grep -qxF 'MAESTRO-CONTEXT-HANDOFF.md' .gitignore || echo 'MAESTRO-CONTEXT-HANDOFF.md' >> .gitignore
      ok "ajouté à .gitignore"
    fi
  fi
  if ask "Committer tout ce qui précède ?"; then
    git add -A
    git commit -q -F - <<'MSG'
feat: v5.4.0 — audit fixes + transfert vers chakerben

- memory-sync: bloc matché par paire ancrée, abandon sans écrire si ambigu,
  écriture atomique tmp+rename sous lock, noms de fichiers validés,
  CLAUDE.md symlinké ignoré, liste on-demand plafonnée
- migrate-v4-to-v5: settings.json / CLAUDE.md / maestro_docs/memory-bank
  ajoutés au backup ; garde sur les options inconnues (exit 2)
- PHILOSOPHY #5 + checker.md: distingue ce qui est enforcé de ce qui est
  seulement instruit (le checker garde Bash pour produire ses preuves)
- tests: suite de régression memory-sync (10 cas) + garde anti-dérive de
  version sur les 9 manifestes, câblées dans npm test et la CI
- owner: arabiipte -> chakerben (dépôt + scope npm @chakerben/maestro)
MSG
    ok "commit créé : $(git rev-parse --short HEAD)"
  elif [ "$DRY_RUN" = "1" ]; then
    warn "commit NON créé (dry-run) — les phases suivantes sont affichées à titre indicatif"
  else
    err "abandon avant commit"; exit 1
  fi
fi

# ── 2. Remote ───────────────────────────────────────────────
step "2/6 Remote"
CURRENT=$(git config --get remote.origin.url)
echo "     actuel : $CURRENT"
if [ "$CURRENT" != "$NEW_URL" ]; then
  act "git remote set-url origin $NEW_URL"
  [ "$DRY_RUN" = "0" ] && git remote set-url origin "$NEW_URL"
fi
if [ "$DRY_RUN" = "0" ]; then
  git ls-remote --exit-code origin >/dev/null 2>&1 \
    || { err "$NEW_URL injoignable — transfert terminé ? auth gh en place ?"; exit 1; }
  ok "origin → $NEW_URL, joignable"
else
  warn "joignabilité NON vérifiée (dry-run)"
fi

# ── 3. Push main ────────────────────────────────────────────
step "3/6 Push main"
if [ "$DRY_RUN" = "0" ]; then
  BEHIND=$(git rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)
  [ "$BEHIND" = "0" ] || { err "$BEHIND commit(s) distants non fusionnés — git pull d'abord"; exit 1; }
fi
if ask "Pousser main vers $NEW_OWNER/$REPO ?"; then
  git push origin main
  ok "main poussé"
  echo "     ⏸  Attends que la CI soit verte avant la phase 4 :"
  echo "        https://github.com/$NEW_OWNER/$REPO/actions"
  ask "CI verte, on tague ?" || { warn "arrêt avant le tag — relance le script quand c'est vert"; exit 0; }
elif [ "$DRY_RUN" = "1" ]; then
  warn "push NON effectué (dry-run)"
else
  warn "push sauté"; exit 0
fi

# ── 4. Tag + publication npm (via CI) ───────────────────────
step "4/6 Tag $TAG → publication npm"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  warn "tag $TAG déjà présent — non recréé"
else
  act "git tag -a $TAG"
  [ "$DRY_RUN" = "0" ] && git tag -a "$TAG" -m "Maestro $VERSION — audit fixes + owner move"
fi
if ask "Pousser le tag (déclenche npm publish sous $SCOPE) ?"; then
  git push origin "$TAG"
  ok "tag poussé — suis le run 'Publish' dans Actions"
elif [ "$DRY_RUN" = "1" ]; then
  warn "tag NON poussé (dry-run) — rien ne serait publié"
else
  warn "tag non poussé — rien n'est publié"
fi

# ── 5. Machine locale ───────────────────────────────────────
step "5/6 ~/.npmrc"
if grep -q "^${SCOPE}:registry=" "$HOME/.npmrc" 2>/dev/null; then
  ok "scope $SCOPE déjà configuré"
else
  act "ajouter '${SCOPE}:registry=https://npm.pkg.github.com' à ~/.npmrc"
  if [ "$DRY_RUN" = "0" ] && ask "L'ajouter ?"; then
    printf '%s:registry=https://npm.pkg.github.com\n' "$SCOPE" >> "$HOME/.npmrc"
    ok "ajouté"
  fi
fi
grep -q "npm.pkg.github.com/:_authToken" "$HOME/.npmrc" 2>/dev/null \
  && ok "token GitHub Packages présent" \
  || warn "pas de _authToken pour npm.pkg.github.com dans ~/.npmrc (nécessaire pour installer/publier à la main)"

# ── 6. Ce qui reste à faire à la main ───────────────────────
step "6/6 Marketplace — à faire toi-même, dans cet ordre"
cat <<EOF

  Ces étapes ne sont pas automatisées à dessein : la seconde peut
  temporairement débrancher les plugins de tes 32 projets.

  1. Tenter la redirection GitHub (non destructif) :
       claude plugin marketplace update maestro
       claude plugin list          # les 7 plugins doivent afficher $VERSION

  2. Seulement si l'étape 1 échoue, et SUR UN PROJET PILOTE d'abord :
       claude plugin marketplace remove maestro
       claude plugin marketplace add $NEW_OWNER/$REPO
     Le nom recréé est identique (maestro), donc les enabledPlugins des
     projets se rebranchent seuls.

  3. Vérifier que le correctif memory-sync est réellement actif :
       cd ~/Documents/Projects/<un-projet-migré>
       git status --porcelain CLAUDE.md     # propre
       # ouvrir une session Claude Code, puis :
       git status --porcelain CLAUDE.md     # rien, ou seulement le bloc <maestro_memory>

  4. Quand tout est vert, déprécier l'ancien package v5 :
       npm deprecate --registry=https://npm.pkg.github.com \\
         "@arabiipte/maestro@>=5.0.0" "Moved to $SCOPE/maestro — see $NEW_OWNER/$REPO"

  5. Supprimer ce script : il a fait son travail.
       git rm scripts/release-5.4.0.sh && git commit -m "chore: retire le script de release 5.4.0"

EOF
ok "terminé"
