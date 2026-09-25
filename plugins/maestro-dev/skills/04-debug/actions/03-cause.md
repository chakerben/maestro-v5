# 03 - Cause

Name the cause, with evidence, and separate it from the symptom.

## Process

1. From the minimal case, trace backwards: where does the wrong value,
   state, or branch first appear? Read the code path; quote the lines.
2. Write `## Cause` as three lines:
   - **Symptom**: where it hurts (file:line, message).
   - **Cause**: where it starts (file:line) and the mechanism, in one sentence.
   - **Why the fix goes at the cause**: what other paths share this cause.
3. State confidence (protocols rule 2). Below "high": say
   which experiment would raise it, run it if it costs < 10 minutes.
3b. If the cause is not found after isolation, or the bug spans layers
   (client → API → DB → infra), or a fix attempt already failed: spawn
   `m-analyst` (fresh context, fable) with the `debug.md` so far; record its
   cause + falsifiable plan in `## Cause`, say in one line why you escalated.
   If the bug is critical (security, concurrency, data loss, cross-project)
   or `m-analyst` came back inconclusive, spawn `m-deep-analyst` (opus) with
   `debug.md` and the previous analysis — a different agent, not a model
   override; a critical bug goes to it directly, without `m-analyst`.
4. If the cause is a design decision recorded in `tech-decisions.md`, do
   NOT reverse it here — stop with `status: cause-found` and a note that
   the fix needs a decision (route to `03-brainstorm` or the human).
5. Set `status: cause-found`.

## Test

- `## Cause` names file:line for both symptom and cause, and they differ
  unless the note explains why they coincide.
- Confidence is stated; anything below "high" names the missing experiment.
- When an analyst ran, `## Cause` carries its plan, which agent produced it
  (`m-analyst` / `m-deep-analyst`) and the one-line reason for the escalation.
