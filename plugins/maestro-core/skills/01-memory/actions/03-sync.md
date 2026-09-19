# 03 - Sync

Force a reference re-sync of the `<maestro_memory>` block in CLAUDE.md.

## Input

Project root.

## Output

CLAUDE.md's `<maestro_memory>` block matching the current memory dir.

## Process

1. Run the hook itself in the project root — it is idempotent and is the
   single source of the block's shape:
   `node ${CLAUDE_PLUGIN_ROOT}/hooks/memory-sync.js`
   It emits tier 1 (`maestro_docs/memory/*.md`) as `@`-references under
   `<!-- always loaded -->`, and tier 2 (`internal/`, `external/`) as plain
   paths under `<!-- read on demand, not auto-loaded -->`. Never rebuild the
   block by hand.
2. Show the resulting diff of CLAUDE.md. If the file did not change, say so.
3. If the hook left the file untouched while the block is stale, the file is
   in a shape it refuses to edit (two blocks, a stray tag outside a code
   fence, a symlinked CLAUDE.md): report which, and let the user resolve it.

## Test

- The block lists every existing memory file and nothing else.
- Running the action twice changes nothing the second time.
