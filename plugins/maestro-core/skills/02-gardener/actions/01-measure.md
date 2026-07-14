# 01 - Measure

Report the context weight of every always-loaded file.

## Input

Project root.

## Output

A weight table + verdict against the 200-line tier-1 budget.

## Process

1. Inventory the always-loaded set: CLAUDE.md, every tier-1 memory file
   (referenced with `@` in the `<maestro_memory>` block), and any other
   `@`-referenced file in CLAUDE.md.
2. For each: line count, approx tokens (lines × 12 as a rough guide), and a
   one-line content summary.
3. Verdict: total vs the 200-line tier-1 budget. Flag files > 60 lines as
   demotion candidates (→ tier 2 on-demand) and sections unrelated to daily
   coding as archive candidates.
4. Recommend next steps (02-archive targets) — recommendations only, no edit.

## Test

- Every always-loaded file appears in the table with a line count.
- Nothing was modified.
