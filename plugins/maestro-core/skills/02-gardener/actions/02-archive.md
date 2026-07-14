# 02 - Archive

Move stale or heavy content out of the always-loaded tier.

## Input

Targets from `01-measure`, or user-designated sections/files.

## Output

Content moved to `maestro_docs/memory/internal/archive/<yyyy-mm>-<topic>.md`,
sources slimmed, references intact.

## Process

1. For each target, classify: **demote** (still useful, rarely needed →
   `internal/`, read on demand) or **archive** (historical → `internal/archive/`).
2. Build the moves. In the source file, leave a one-line pointer:
   `Details: maestro_docs/memory/internal/<file>.md`.
3. Show the full before/after diff. **Wait for approval.**
4. Apply, then re-run the measure summary to show the new weight.

## Test

- No content was destroyed — everything moved lives in `internal/` or
  `internal/archive/` with a pointer left behind.
- Tier-1 total decreased.
