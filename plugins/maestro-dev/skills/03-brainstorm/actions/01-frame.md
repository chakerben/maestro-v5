# 01 - Frame

Set the ground before asking anything.

## Input

The request, free text.

## Output

`maestro_docs/tasks/<yyyy_mm_dd>_<slug>/design.md` created from
`assets/design-template.md`, frontmatter `status: exploring`, with the problem
restated and the unknowns listed. No question asked yet.

## Process

1. **Resolve the folder.** Slug from the request. If a folder for this subject
   already exists with a `design.md`, read it and resume from its journal
   instead of starting over — announce the resume point in one line.
2. **Restate the problem in one sentence**, using only what the request
   contains. If the restatement needs a word the request never used, that word
   is an assumption: it goes in the unknowns, not the restatement.
3. **Read before claiming.** Open the memory bank (`project-brief.md`,
   `tech-decisions.md`, `patterns.md`) and the two or three files the request
   most plausibly touches. Record what you read in `## Contexte lu`, with paths.
4. **Detect the domain** and announce the expert posture you are adopting
   (`../../references/expert-postures.md`). The posture decides which unknowns
   are shape-changing: an auth feature makes "who can call this" a shape
   question, a UI feature makes "what does the empty state say" one.
5. **List the unknowns**, each as a question you could actually ask a human,
   sorted by how much the answer changes the shape of the solution. Mark the
   ones the codebase already answers — those are not questions, those are reads.
6. **Check the off-ramp.** Objective already one sentence, one reasonable
   approach, conventions already recorded → say so and hand off to
   `maestro-dev:01-plan`. Set `status: dropped` with the reason "off-ramp:
   pas de question ouverte".

## Test

- The restatement contains no term absent from the request.
- Every claim in `## Contexte lu` carries a path.
- The unknowns are ordered, and each is phrased as a question.
- Unknowns the codebase already answers are marked as read, not asked.
