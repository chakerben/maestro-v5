#!/bin/bash
# ============================================================
# Maestro — prune-installed.sh
#
# `claude plugin list` traîne une entrée par copie --scope project jamais
# désinstallée : worktrees de sessions passées sous /private/tmp, dossiers
# supprimés… Elles restent à leur version d'installation pour toujours et
# faussent tout contrôle "plus aucune version antérieure".
#
# Ce script retire de ~/.claude/plugins/installed_plugins.json les entrées
# scope=project dont le chemin N'EXISTE PLUS. Rien d'autre.
#
#   ./scripts/prune-installed.sh            # dry-run : montre ce qui serait retiré
#   ./scripts/prune-installed.sh --apply    # écrit, après sauvegarde horodatée
# ============================================================
set -euo pipefail
APPLY=0
for arg in "$@"; do case "$arg" in --apply) APPLY=1 ;; *) echo "option inconnue : $arg (--apply)" >&2; exit 2 ;; esac; done
F="$HOME/.claude/plugins/installed_plugins.json"
[ -f "$F" ] || { echo "❌ $F introuvable"; exit 1; }
# Le CLI peut tourner comme binaire `claude`, comme script `…/bin/claude`, ou
# comme `node …/claude` (installation npm) : les trois réécrivent ce fichier.
if pgrep -x claude >/dev/null 2>&1 || pgrep -f '(^|/)claude( |$)' >/dev/null 2>&1 || pgrep -f 'node.*claude' >/dev/null 2>&1; then
  echo "❌ une session claude tourne — ferme-la d'abord (le CLI réécrit ce fichier)"; exit 1
fi
python3 - "$F" "$APPLY" <<'PY'
import json, os, sys, shutil, time
f, apply = sys.argv[1], sys.argv[2] == "1"
d = json.load(open(f))
# Schéma minimal : au moins une entrée portant une clé "scope". Sinon le format
# a changé et on ne sait plus ce qu'on retirerait — on s'arrête.
def has_scope(o):
    if isinstance(o, dict):
        return "scope" in o or any(has_scope(v) for v in o.values())
    return isinstance(o, list) and any(has_scope(v) for v in o)
if not has_scope(d):
    sys.exit(f"❌ {f} : aucune entrée avec une clé \"scope\" — format inattendu, rien n'est touché")
dead = []
def is_dead(o):
    if isinstance(o, dict) and o.get("scope") == "project":
        path = o.get("projectPath") or o.get("project")
        return isinstance(path, str) and not os.path.isdir(path)
    return False
def walk(o):
    if isinstance(o, list):
        keep = []
        for v in o:
            if is_dead(v): dead.append(v.get("projectPath") or v.get("project"))
            else: keep.append(walk(v))
        return keep
    if isinstance(o, dict):
        return {k: walk(v) for k, v in o.items()}
    return o
new = walk(d)
print(f"entrées mortes : {len(dead)}")
for p in sorted(set(dead)): print(f"  - {p}")
if not dead: sys.exit(0)
if not apply:
    print("\n(dry-run — relance avec --apply pour écrire)"); sys.exit(0)
bak = f + "." + time.strftime("%Y%m%d-%H%M%S") + ".bak"
shutil.copy2(f, bak)
tmp = f + ".tmp"
with open(tmp, "w") as out:
    json.dump(new, out, indent=2, ensure_ascii=False); out.write("\n")
os.replace(tmp, f)
print(f"\n✅ écrit — sauvegarde : {bak}")
PY
