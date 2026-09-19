#!/bin/bash
# ============================================================
# Maestro — scripts/lib/fleet.sh
# Shared project discovery for the fleet scripts (update-projects.sh,
# fleet-apply.sh). Source it; it defines functions only, no side effects.
# Requires: PROJECTS_ROOT, MARKETPLACE (default "maestro"), python3.
# ============================================================
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Documents/Projects}"
MARKETPLACE="${MARKETPLACE:-maestro}"

# Quels plugins maestro ce projet déclare-t-il ? (settings.json ET settings.local.json —
# 5.9.4 : uma-place ne déclarait les siens que dans le .local et était invisible)
plugins_of() {
  { python3 - "$1" <<'PY' 2>/dev/null
import json, sys, os
seen = set()
for f in ("settings.json", "settings.local.json"):
    p = os.path.join(sys.argv[1], ".claude", f)
    try:
        d = json.load(open(p))
    except Exception:
        continue
    for k in (d.get("enabledPlugins") or {}):
        name, _, mk = k.partition("@")
        if mk == "maestro" and name not in seen:
            seen.add(name); print(name)
PY
    installed_plugins_of "$1"
  } | awk 'NF && !seen[$0]++'
}

# Les plugins @maestro INSTALLÉS pour ce chemin, d'après installed_plugins.json.
# 5.9.5 : un worktree gwt ou un projet dont le .claude/settings.json ne déclare rien
# a quand même une copie installée — sans ça elle reste à sa version d'origine à vie.
installed_plugins_of() {
  python3 - "$1" <<'PYP' 2>/dev/null
import json, os, re, sys
target = os.path.realpath(sys.argv[1])
f = os.path.expanduser("~/.claude/plugins/installed_plugins.json")
try:
    d = json.load(open(f))
except Exception:
    raise SystemExit(0)
out = []
def name_from(chain):
    for k in reversed(chain):
        m = re.match(r"^(maestro-[a-z]+)(@maestro)?$", str(k))
        if m:
            return m.group(1)
    return None
def walk(o, chain):
    if isinstance(o, dict):
        if o.get("scope") == "project":
            p = o.get("projectPath") or o.get("project")
            if isinstance(p, str) and os.path.realpath(p) == target:
                n = o.get("name") or o.get("plugin") or name_from(chain)
                if n and str(n).startswith("maestro-") and n not in out:
                    out.append(str(n).split("@")[0])
        for k, v in o.items(): walk(v, chain + [k])
    elif isinstance(o, list):
        for v in o: walk(v, chain)
walk(d, [])
for n in out: print(n)
PYP
}

# La source de vérité de `claude plugin list` : installed_plugins.json. Chaque copie
# --scope project y a son chemin. On prend celles dont le chemin existe encore.
installed_projects() {
  python3 - <<'PYI' 2>/dev/null
import json, os
p = os.path.expanduser("~/.claude/plugins/installed_plugins.json")
try:
    d = json.load(open(p))
except Exception:
    raise SystemExit(0)
out = set()
def walk(o):
    if isinstance(o, dict):
        if o.get("scope") == "project":
            path = o.get("projectPath") or o.get("project")
            if isinstance(path, str) and os.path.isdir(path):
                out.add(path)
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(d)
for x in sorted(out): print(x)
PYI
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

# Découverte = installed_plugins.json (vérité) + scan de PROJECTS_ROOT (profondeur 3,
# pour .worktrees/<repo>/<branche>) + projets connus de ~/.claude.json, dédoublonnés.
# Un dossier de sauvegarde (.maestro-v4-backup-*, .maestro-doctor-backup-*) contient
# un .claude/ copié : ce n'est pas un projet. Idem node_modules.
is_project() {
  case "$1" in
    */.maestro-*backup*|*/node_modules/*|*/.git/*) return 1 ;;
    *) return 0 ;;
  esac
}

discover() {
  { installed_projects
    [ -d "$PROJECTS_ROOT" ] && find "$PROJECTS_ROOT" -maxdepth 3 -mindepth 1 -type d -name '.claude' -exec dirname {} \; 2>/dev/null
    known_projects
  } | sort -u | while IFS= read -r d; do is_project "$d" && echo "$d"; done
}

