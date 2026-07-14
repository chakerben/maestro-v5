# 02 - Review

Check memory files for staleness and internal contradictions.

## Input

`maestro_docs/memory/` contents.

## Output

A findings report: stale claims, contradictions, gaps — each with evidence
and a proposed fix. No file modified.

## Process

1. Read every memory file.
2. **Staleness pass.** For each factual claim (dep exists, pattern used,
   service integrated), spot-check against the codebase. Mark `stale` with
   the contradicting evidence (file + line or dep list).
3. **Contradiction pass.** Compare claims across files and against CLAUDE.md.
   Mark conflicting pairs.
4. **Gap pass.** Major visible concerns with no memory coverage (e.g. a
   `prisma/` dir but no data-layer notes).
5. Report grouped by severity: contradiction > stale > gap. Offer to apply
   fixes via `01-generate`.

## Test

- Every finding carries evidence (a path, a dep name, or a quoted line).
- No memory file was modified by this action.
