---
name: 04-doctor
description: Verify the health of a Maestro install in the current project — plugins enabled, hooks compliant, memory bank coherent, and NO leftovers from Maestro v4 or third-party orchestrators (claude-flow, ruv-swarm). Use after a migration, when something feels broken, or as a periodic checkup. Not for first-time setup (00-onboard).
argument-hint: check | fix
allowed-tools: Bash   # turn-scoped: the !`…` injections above use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: doctor

## Live state (computed at invocation)

Maestro plugins seen by Claude Code here:
!`claude plugin list 2>/dev/null | grep -B1 -A3 '@maestro' || echo "(claude plugin list unavailable or no @maestro plugin)"`

Project settings hooks (must be absent — v4 came back through here):
!`[ -f .claude/settings.json ] && node -e 'try{const d=JSON.parse(require("fs").readFileSync(".claude/settings.json","utf8"));const h=d.hooks||{};const n=Object.values(h).flat().flatMap(g=>g.hooks||[]).length;console.log(n?("⚠ "+n+" hook(s) in .claude/settings.json: "+JSON.stringify(h)):"no hooks in .claude/settings.json ✓");const deny=(d.permissions||{}).deny||[];console.log(deny.length?("permissions.deny: "+deny.length+" entr"+(deny.length>1?"ies":"y")):"⚠ permissions.deny empty (see onboard 04-scaffold step 4b)")}catch(e){console.log("⚠ malformed .claude/settings.json: "+e.message)}' || echo "(no .claude/settings.json)"`

v4 leftovers:
!`for f in scripts/hooks .claude/quality-gates.json .claude/version.txt docs/memory-bank maestro_docs/memory-bank; do [ -e "$f" ] && echo "⚠ $f exists"; done; grep -rl "claude-flow\|ruv-swarm" .claude .mcp.json 2>/dev/null | sed 's/^/⚠ orchestrator ref: /'; echo "(scan done)"`

Memory bank:
!`[ -d maestro_docs/memory ] && ls maestro_docs/memory | head -20 || echo "(no maestro_docs/memory)"; [ -f CLAUDE.md ] && echo "<maestro_memory> tags in CLAUDE.md: $(grep -c "maestro_memory" CLAUDE.md)" || echo "(no CLAUDE.md)"`

The coherence checker. Its most important job: guarantee the v4 runtime
machinery that caused RAM crashes never comes back.

## Actions

| #  | Action  | Role                                              | Input        |
|----|---------|---------------------------------------------------|--------------|
| 01 | `check` | Full diagnostic, findings by severity             | project root |
| 02 | `fix`   | Apply safe corrections, each approved             | check report |

Run `check` first, always. `fix` only consumes a check report from this
session. Before running an action, read its file in `actions/`.
