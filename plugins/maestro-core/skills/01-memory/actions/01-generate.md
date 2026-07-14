# 01 - Generate

Read the codebase and write/refresh the memory bank files.

## Input

Project root. Optionally a scope hint ("just tech-decisions").

## Output

Refreshed files under `maestro_docs/memory/`, each change approved.

## Process

1. **Survey.** Read package.json/pyproject, top-level structure, main config
   files (next.config, prisma/schema.prisma, app.json), CI workflows, and the
   3–5 most central source files (entry points, core services).
2. **project-brief.md.** One paragraph: what the product is, for whom, in
   production or not. Ask the user for anything not inferable — never invent.
3. **tech-decisions.md.** For each significant choice found (framework, DB,
   auth, styling, testing, deployment): the choice + the visible reason. Flag
   `(reason unknown — confirm?)` where the WHY is not evident.
4. **patterns.md.** Project-specific conventions actually observed in the
   code: folder layout logic, naming, error handling style, i18n approach,
   API shape. Only patterns seen ≥2 times.
5. Show each file as a diff against the current version. Write on approval.

## Test

- Every statement in the generated files is traceable to something read in
  the codebase or explicitly given by the user this session.
- No file exceeds ~60 lines (memory is dense, not exhaustive).
