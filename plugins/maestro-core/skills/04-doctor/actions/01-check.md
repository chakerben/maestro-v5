# 01 - Check

Full install diagnostic.

## Input

Project root.

## Output

A findings report grouped by severity: 🔴 contraband / 🟠 broken / 🟡 drift /
🟢 healthy. No file modified.

## Process

1. **🔴 Contraband scan (the crash guards).** Flag ANY of:
   - `scripts/hooks/` directory with v4 hook scripts (maestro-router.py,
     post-edit-typecheck.sh, stop-quality-gate.sh, etc.)
   - Hooks in `.claude/settings.json` or `~/.claude/settings.json` whose
     command mentions `tsc`, `typecheck`, `jest`, `vitest`, `prettier`,
     `eslint`, `pnpm test`, or `npm test`
   - Any reference to `claude-flow` or `ruv-swarm` in settings, `.mcp.json`,
     or `~/.claude.json`
   - Hooks, counted in three buckets across active settings + plugin hooks:
     **Maestro hooks** (memory-sync, bash-guard) — more than 2 = 🔴;
     **official plugin hooks** (`*@claude-plugins-official`: LSP,
     security-guidance…) — allowed, list them, no severity;
     **other hooks** (any other plugin, settings, or script) — 🔴 smuggled.
2. **🟠 Broken scan.** `maestro_docs/` missing pieces; `<maestro_memory>`
   block absent or referencing missing files; expected Maestro plugins not
   in `claude plugin list`; LSP plugin installed but its binary not on PATH;
   `permissions.deny` canonical entries missing from `.claude/settings.json`
   (the list is in onboard `04-scaffold` step 4b — bash-guard is only the
   accident guard, `permissions.deny` is the enforced layer).
3. **🟡 Drift scan.** Memory files untouched > 60 days; tier-1 context over
   the 200-line budget (delegate detail to gardener 01-measure); official
   plugin recommendations for this stack not installed; session model is
   not `sonnet` or unset (`.claude/settings.json` `"model"`) — the ladder
   assumes sonnet; opus as session default pays the expert rate for CRUD
   (`references/model-policy.md`; onboard `04-scaffold` step 4c sets it).
4. **Runtime spot-check.** Suggest the user run
   `ps aux | grep -E "jest|tsc|claude-flow|ruv-swarm" | grep -v grep` and
   report phantom processes.
5. Print the report. If any 🔴, say plainly: "run `fix` — these caused the
   2026-07 crashes."

## Test

- Every finding carries a path and the matched evidence.
- Nothing was modified.
