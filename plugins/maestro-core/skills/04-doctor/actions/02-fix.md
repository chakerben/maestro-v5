# 02 - Fix

Apply safe corrections from a check report.

## Input

The findings of `01-check` from this session.

## Output

Corrections applied with per-item approval; a backup of everything touched.

## Process

1. **Backup first.** Copy every file about to change into
   `.maestro-doctor-backup-<timestamp>/`.
2. **🔴 Contraband, in order:**
   - Move `scripts/hooks/` v4 scripts into the backup (out of the project).
   - Rewrite the offending settings hooks blocks to `"hooks": {}` — show diff,
     approve, apply.
   - Remove claude-flow / ruv-swarm entries from `.mcp.json` / settings —
     diff, approve, apply. Suggest `claude mcp remove <name>` for CLI-managed ones.
3. **🟠 Broken:** re-scaffold missing `maestro_docs/` pieces (delegate to
   onboard 04-scaffold); re-sync the memory block (delegate to memory 03-sync);
   list the `claude plugin install` commands for missing plugins; merge the
   missing `permissions.deny` entries (delegate to onboard 04-scaffold step 4b
   — it is idempotent and never drops other keys).
4. **🟡 Drift:** recommend, don't apply — point to gardener and 01-memory.
5. Re-run the check-scan logic and print the before/after severity counts.

## Test

- A backup directory exists containing the pre-fix state of every touched file.
- Re-running `check` reports zero 🔴 findings.
