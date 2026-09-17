# 03 - Cause

Name the cause, with evidence, and separate it from the symptom.

## Process

1. From the minimal case, trace backwards: where does the wrong value,
   state, or branch first appear? Read the code path; quote the lines.
2. Write `## Cause` as three lines:
   - **Symptom**: where it hurts (file:line, message).
   - **Cause**: where it starts (file:line) and the mechanism, in one sentence.
   - **Why the fix goes at the cause**: what other paths share this cause.
3. State confidence (`cognitive-protocols.md` rule 2). Below "high": say
   which experiment would raise it, run it if it costs < 10 minutes.
4. If the cause is a design decision recorded in `tech-decisions.md`, do
   NOT reverse it here — stop with `status: cause-found` and a note that
   the fix needs a decision (route to `03-brainstorm` or the human).
5. Set `status: cause-found`.

## Test

- `## Cause` names file:line for both symptom and cause, and they differ
  unless the note explains why they coincide.
- Confidence is stated; anything below "high" names the missing experiment.
