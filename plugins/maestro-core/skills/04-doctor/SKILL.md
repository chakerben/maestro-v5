---
name: 04-doctor
description: Verify the health of a Maestro install in the current project — plugins enabled, hooks compliant, memory bank coherent, and NO leftovers from Maestro v4 or third-party orchestrators (claude-flow, ruv-swarm). Use after a migration, when something feels broken, or as a periodic checkup. Not for first-time setup (00-onboard).
argument-hint: check | fix
allowed-tools: Bash   # turn-scoped: the !`…` injections below use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: doctor

## Live state (computed at invocation)

Maestro plugins seen by Claude Code here:
!`claude plugin list 2>/dev/null | grep -B1 -A3 '@maestro' || echo "(claude plugin list unavailable or no @maestro plugin)"`

Hooks every active settings file declares (project, local, user — v4 came back through here), and every plugin's hook inventory (the three buckets of 01-check: Maestro = memory-sync + bash-guard only, official = allowed, other = smuggled):
!`for f in .claude/settings.json .claude/settings.local.json "$HOME/.claude/settings.json"; do [ -f "$f" ] && node -e 'const f=process.argv[1];try{const h=JSON.parse(require("fs").readFileSync(f,"utf8")).hooks||{};const n=Object.values(h).flat().flatMap(g=>g.hooks||[]).length;console.log(n?("⚠ "+n+" hook(s) in "+f+": "+JSON.stringify(h)):"no hooks in "+f+" ✓")}catch(e){console.log("⚠ malformed "+f+": "+e.message)}' "$f"; done; for id in $(claude plugin list 2>/dev/null | grep -oE '[a-z0-9-]+@[a-z0-9-]+' | sort -u); do claude plugin details "$id" 2>/dev/null | grep -iE '^(Plugin|Name)|hook' | tr '\n' ' '; echo; done | grep -i hook | sed 's/^/plugin hooks: /' || echo "(no plugin declares a hook, or claude plugin details unavailable)"`

Project settings permissions:
!`[ -f .claude/settings.json ] && node -e 'try{const d=JSON.parse(require("fs").readFileSync(".claude/settings.json","utf8"));const h=d.hooks||{};const n=Object.values(h).flat().flatMap(g=>g.hooks||[]).length;console.log(n?("⚠ "+n+" hook(s) in .claude/settings.json: "+JSON.stringify(h)):"no hooks in .claude/settings.json ✓");const deny=(d.permissions||{}).deny||[];console.log(deny.length?("permissions.deny: "+deny.length+" entr"+(deny.length>1?"ies":"y")):"⚠ permissions.deny empty (see onboard 04-scaffold step 4b)");console.log(deny.includes("Agent(model:*)")?"Agent(model:*) ✓ model pins enforced":"⚠ Agent(model:*) missing — a dispatch can override any agent model pin (04-scaffold 4b)");const dead=deny.filter(r=>/\|/.test(r));if(dead.length)console.log("⚠ dead deny rule(s) — a rule with a pipe never matches a subcommand: "+dead.join(", "));const broad=deny.filter(r=>/--force\*|push -f\*/.test(r));if(broad.length)console.log("ℹ over-broad: "+broad.join(", ")+" also blocks --force-with-lease (yours to keep or narrow)")}catch(e){console.log("⚠ malformed .claude/settings.json: "+e.message)}' || echo "(no .claude/settings.json)"`

v4 leftovers:
!`for f in scripts/hooks .claude/quality-gates.json .claude/version.txt docs/memory-bank maestro_docs/memory-bank; do [ -e "$f" ] && echo "⚠ $f exists"; done; grep -rl "claude-flow\|ruv-swarm" .claude .mcp.json 2>/dev/null | sed 's/^/⚠ orchestrator ref: /'; echo "(scan done)"`

Memory bank:
!`[ -d maestro_docs/memory ] && ls maestro_docs/memory | head -20 || echo "(no maestro_docs/memory)"; [ -f CLAUDE.md ] && echo "<maestro_memory> tags on their own line in CLAUDE.md: $(grep -cE '^</?maestro_memory>[[:space:]]*$' CLAUDE.md) (2 = one well-formed block)" || echo "(no CLAUDE.md)"`

The coherence checker. Its most important job: guarantee the v4 runtime
machinery that caused RAM crashes never comes back.

## Actions

| #  | Action  | Role                                              | Input        |
|----|---------|---------------------------------------------------|--------------|
| 01 | `check` | Full diagnostic, findings by severity             | project root |
| 02 | `fix`   | Apply safe corrections, each approved             | check report |

Run `check` first, always. `fix` only consumes a check report from this
session. Before running an action, read its file in `actions/`.
