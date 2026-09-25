---
name: 04-debug
description: Use when behaviour that already exists is wrong — a bug report, a crash, a stack trace, "ça marche pas", "it worked yesterday", a failing test nobody understands, wrong output for a known input. Drives reproduce → isolate → cause → fix + regression test, with resumable state. Not for building something new (00-sdlc / 01-plan), not for an open design question (03-brainstorm), not for a performance complaint without a defect (maestro-quality:02-perf-audit).
effort: medium
argument-hint: "<what is wrong, or a stack trace / failing test path>"
allowed-tools: Bash   # turn-scoped: the !`…` injections below use shell builtins, pipes and $(…) that pattern grants do not cover
model: fable
---

# Skill: debug

Fix the cause, not the symptom — and prove it with a test that failed before
the fix and passes after. The order is not negotiable: nothing is changed in
the code before the bug has been reproduced on demand.

## Live state (computed at invocation)

!`git status --short | head -15; echo "branch: $(git branch --show-current)"; git log --oneline -5`

Open debug sessions:
!`ls -d maestro_docs/tasks/*/debug.md 2>/dev/null | while read f; do echo "$f  $(grep -m1 '^status:' "$f")"; done; echo "(scan done)"`

## Actions

| #  | Action      | Role                                                         | Input            |
|----|-------------|--------------------------------------------------------------|------------------|
| 01 | `reproduce` | Turn the report into a command that fails on demand          | the report       |
| 02 | `isolate`   | Shrink to the smallest failing case; bisect if needed        | repro command    |
| 03 | `cause`     | Name the cause with evidence; distinguish it from the symptom | isolated case   |
| 04 | `fix`       | Regression test first (red), fix (green), no scope creep     | named cause      |

Run `01 → 04`. Before running an action, read its file in `actions/`.
Adopt the **Root-cause analyst** posture
(`${CLAUDE_PLUGIN_ROOT}/references/expert-postures.md`) and protocols rules
1, 2, 5, 6, 7 (`${CLAUDE_PLUGIN_ROOT}/skills/06-protocols/SKILL.md`).

## Binding rules

**No repro, no edit.** Until action 01 produces a command (or a test) whose
exit code says "still broken", the only files touched are `debug.md` and,
at most, a throwaway script under `maestro_docs/tasks/<folder>/`.

**The symptom is where it hurts; the cause is where it starts.** Action 03
must state both, and why the fix goes at the cause. "Add a null check where
it crashes" is a symptom fix unless the null is legitimately possible there.

**One bug, one folder, one fix** (protocols rule 5). Other defects met on
the way go to `debug.md` under `## Seen on the way`, then to
`maestro-pm:03-ticket` when installed — never fixed in passing.

**Model ladder.** This skill runs on fable: reproducing and isolating is
reasoning, and a surgical fix is worth more than a fast one. Stuck after
isolation, multi-layer, or a failed fix → action 03 spawns `m-analyst`
(fresh context, fable). Still inconclusive, or critical from the start
(security, concurrency, data loss, cross-project) → `m-deep-analyst` (opus).
Opus is a different agent, never a model override.

**Resume.** `debug.md` carries `status: reproducing | isolating | cause-found
| fixed | not-reproducible`. On entry, if the folder exists, continue from
the recorded status. `not-reproducible` after three honest attempts is a
legitimate end state: record what was tried, hand the report back.

**If the project has an `ar` locale**, every repro is also run under `ar`
before declaring the fix complete — always check direction/locale dependence.

## Where the work lands

`maestro_docs/tasks/<yyyy_mm_dd>_<slug>/debug.md` from `assets/debug-template.md`,
plus the regression test in the project's test tree.
