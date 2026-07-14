# 02 - Explore

Read the codebase for projection and feasibility.

## Process

1. Map the integration points: which modules/routes/models this touches.
   Use LSP navigation when available; read the memory bank first
   (patterns.md tells you the conventions).
2. Answer each unknown from 01 with codebase evidence where possible; the
   rest become explicit questions (interactive) or logged assumptions (auto).
3. Feasibility notes: existing utilities to reuse, migrations needed, i18n/RTL
   impact if an `ar` locale exists, test surface.
4. Output a short exploration digest (<= 30 lines) — it feeds the plan, and
   ONLY the digest goes into the plan context (context budget rule).

## Test

- Every integration point cites a real path.
- The digest fits in 30 lines.
