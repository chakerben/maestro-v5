# 03 - Contradictions

Detect conflicting rules across the context files.

## Input

CLAUDE.md + all memory files (+ `.claude/settings.json` permissions if present).

## Output

A conflict report: each conflict = the two quoted statements, their files,
and a proposed resolution. No file modified.

## Process

1. Extract every normative statement ("always X", "never Y", "use Z", stack
   claims, workflow rules).
2. Pairwise-compare for: direct contradiction, subsumption (one rule makes
   another dead), and drift (rule vs observed codebase reality).
3. For each conflict, propose the resolution: which statement wins and WHY
   (recency, specificity, or codebase evidence).
4. Offer to apply resolutions (each shown as a diff, each approved separately).

## Test

- Every reported conflict quotes both statements with their file paths.
- Nothing was modified without approval.
