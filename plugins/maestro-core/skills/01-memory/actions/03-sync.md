# 03 - Sync

Force a reference re-sync of the `<maestro_memory>` block in CLAUDE.md.

## Input

Project root.

## Output

CLAUDE.md's `<maestro_memory>` block matching the current memory dir.

## Process

1. List `maestro_docs/memory/*.md` (tier 1) and `internal/`+`external/`
   subdirs (tier 2, on-demand).
2. Rebuild the block exactly as the SessionStart hook would:
   tier 1 as `@`-references, tier 2 as plain paths under a
   `<!-- read on demand -->` comment.
3. Replace the existing block (or append if absent). Show the diff first.

## Test

- The block lists every existing memory file and nothing else.
- Running the action twice changes nothing the second time.
