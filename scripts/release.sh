#!/bin/bash
# ============================================================
# Maestro — release.sh
#
# Publie une version : bump des 9 manifestes, commit, push, tag.
# Le tag déclenche publish.yml, qui republie sur GitHub Packages.
#
# USAGE :
#   ./scripts/release.sh 5.5.0 --dry-run   # montre tout, ne touche à rien
#   ./scripts/release.sh 5.5.0             # exécute, confirmation par phase
#   ./scripts/release.sh                   # reprend la version de package.json
#
# PRINCIPES :
#   - set -euo pipefail, option inconnue = exit 2
#   - --dry-run ne mute rien et ne prétend jamais avoir vérifié
#   - confirmation avant chaque phase qui écrit ou pousse
#   - idempotent : relançable après un échec, il reprend où il en est
#   - rien de destructif (pas de rm -rf, pas de force, pas de branch -M)
# ============================================================

set -euo pipefail

DRY_RUN=0
VERSION=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "option inconnue : $arg (--dry-run)" >&2; exit 2 ;;
    *)
      [ -z "$VERSION" ] || { echo "version déjà donnée ($VERSION), argument en trop : $arg" >&2; exit 2; }
      [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version invalide : $arg (attendu X.Y.Z)" >&2; exit 2; }
      VERSION="$arg" ;;
  esac
done

B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
step() { echo -e "\n${B}▶ $1${N}"; }
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
CURRENT=$(node -p "require('$ROOT/package.json').version")
[ -n "$VERSION" ] || VERSION="$CURRENT"
TAG="v$VERSION"

echo -e "${B}╔══════════════════════════════════════════════╗${N}"
echo -e "${B}║  Maestro — release $TAG${N}"
echo -e "${B}╚══════════════════════════════════════════════╝${N}"
echo "  Dépôt      : $ROOT"
echo "  package.json : $CURRENT   →   cible : $VERSION"
echo "  Dry-run    : $DRY_RUN"

# ── 0. Préflight ────────────────────────────────────────────
step "0/5 Préflight"
[ -f "$ROOT/.claude-plugin/marketplace.json" ] || { err "pas le dépôt maestro"; exit 1; }
ok "dépôt reconnu"

if [ -f "$ROOT/.git/index.lock" ]; then
  if pgrep -x git >/dev/null 2>&1; then err "un process git tourne — ferme-le"; exit 1; fi
  act "rm .git/index.lock (verrou résiduel)"
  if [ "$DRY_RUN" = "0" ]; then rm -f "$ROOT/.git/index.lock"; ok "verrou retiré"
  else warn "verrou TOUJOURS présent (dry-run)"; fi
else
  ok "pas de verrou git"
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
  warn "le tag $TAG existe déjà localement"
fi
grep -q "^## $VERSION" CHANGELOG.md \
  && ok "CHANGELOG a une section $VERSION" \
  || warn "CHANGELOG n'a pas de section '## $VERSION' — pense à l'écrire"

# ── 1. Bump des manifestes ──────────────────────────────────
step "1/5 Versions"
if [ "$CURRENT" = "$VERSION" ]; then
  ok "package.json déjà en $VERSION"
else
  act "passer les 9 manifestes de $CURRENT à $VERSION"
  if [ "$DRY_RUN" = "0" ] && ask "Bumper ?"; then
    for f in package.json .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json; do
      node -e '
        const fs=require("fs"), f=process.argv[1], from=process.argv[2], to=process.argv[3];
        const s=fs.readFileSync(f,"utf8");
        const out=s.replace(new RegExp(`("version":\\s*")${from.replace(/\./g,"\\.")}(")`), `$1${to}$2`);
        if (out===s) { console.error("  inchangé: "+f); process.exit(1); }
        fs.writeFileSync(f,out);
      ' "$f" "$CURRENT" "$VERSION" || { err "bump raté sur $f"; exit 1; }
    done
    ok "9 manifestes en $VERSION"
  elif [ "$DRY_RUN" = "1" ]; then
    warn "bump NON effectué (dry-run)"
  else
    err "abandon"; exit 1
  fi
fi

step "1b/5 Tests"
act "npm test"
if [ "$DRY_RUN" = "0" ]; then
  npm test >/tmp/maestro-release-test.log 2>&1 \
    || { err "npm test ROUGE — /tmp/maestro-release-test.log"; tail -20 /tmp/maestro-release-test.log; exit 1; }
  ok "tests verts"
else
  warn "tests NON exécutés (dry-run)"
fi

# ── 2. Commit ───────────────────────────────────────────────
step "2/5 Commit"
if [ -z "$(git status --porcelain)" ]; then
  ok "rien à committer"
else
  git status --short | sed 's/^/     /'
  if ask "Committer tout ce qui précède ?"; then
    read -r -p "  Message (vide = 'chore(release): $TAG') : " MSG || MSG=""
    [ -n "$MSG" ] || MSG="chore(release): $TAG"
    git add -A && git commit -q -m "$MSG"
    ok "commit : $(git rev-parse --short HEAD)"
  elif [ "$DRY_RUN" = "1" ]; then
    warn "commit NON créé (dry-run)"
  else
    err "abandon avant commit"; exit 1
  fi
fi

# ── 3. Push main ────────────────────────────────────────────
step "3/5 Push main"
ORIGIN=$(git config --get remote.origin.url)
echo "     origin : $ORIGIN"
if [ "$DRY_RUN" = "0" ]; then
  git ls-remote --exit-code origin >/dev/null 2>&1 || { err "origin injoignable"; exit 1; }
  git fetch -q origin main || { err "git fetch origin main a échoué"; exit 1; }
  BEHIND=$(git rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)
  [ "$BEHIND" = "0" ] || { err "$BEHIND commit(s) distants non fusionnés — git pull d'abord"; exit 1; }
  ok "origin joignable, rien en retard"
else
  warn "joignabilité NON vérifiée (dry-run)"
fi
if ask "Pousser main ?"; then
  git push origin main
  ok "main poussé"
  echo "     ⏸  Attends la CI verte : ${ORIGIN%.git}/actions"
  ask "CI verte, on tague ?" || { warn "arrêt avant le tag — relance quand c'est vert"; exit 0; }
elif [ "$DRY_RUN" = "1" ]; then
  warn "push NON effectué (dry-run)"
else
  warn "push sauté"; exit 0
fi

# ── 4. Tag → publication npm ────────────────────────────────
step "4/5 Tag $TAG"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  warn "tag $TAG déjà présent — non recréé"
else
  act "git tag -a $TAG"
  [ "$DRY_RUN" = "0" ] && git tag -a "$TAG" -m "Maestro $VERSION"
fi
if ask "Pousser le tag (déclenche npm publish) ?"; then
  git push origin "$TAG"
  ok "tag poussé — suis le run 'Publish' dans Actions"
elif [ "$DRY_RUN" = "1" ]; then
  warn "tag NON poussé (dry-run)"
else
  warn "tag non poussé — rien n'est publié"
fi

# ── 5. Propagation ──────────────────────────────────────────
step "5/5 Propager aux projets"
cat <<EOF

  Le marketplace ne se met PAS à jour tout seul, et les copies
  installées dans tes projets non plus. Une fois la CI verte :

    claude plugin marketplace update maestro
    ./scripts/update-projects.sh --list
    ./scripts/update-projects.sh <un-projet>     # pilote
    ./scripts/update-projects.sh --all

  Si l'auto-update est activé (/plugin → Marketplaces → maestro),
  seul le \`marketplace update\` reste nécessaire.

EOF
ok "terminé"
