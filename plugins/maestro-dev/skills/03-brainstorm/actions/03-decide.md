# 03 - Decide

Turn the journal into a decision that survives contact with a reviewer.

## Input

`design.md` with a complete journal.

## Output

`## Approaches` and `## Decision` filled, devil-advocate verdict quoted.

## Process

1. **Write 2–3 approaches**, each with: what it is in two lines, what it costs
   (effort, dependencies, what it makes harder later), and the condition under
   which it wins. Approaches that differ only in naming are one approach —
   find a genuinely different shape or say plainly that only one exists.
   One legitimate approach is always on the table: **do not build**. Write
   it when the journal supports it.
2. **Name your recommendation and the condition it rests on.** "A, tant que le
   volume reste sous X" is a recommendation. "A me semble mieux" is a
   preference.
3. **Run `m-devil-advocate`** on the recommendation. Give it the design path,
   not the design text. It returns a verdict — `proceed`, `proceed with
   changes`, or `reconsider` — and its top three risks.
   Write the prompt without telling it what not to flag. If the prompt you are
   about to send contains "ne signale pas", "ce n'est pas un défaut ici", "le
   contexte justifie" — rewrite it: you are pre-judging to spare yourself a
   round.
4. **Quote the verdict verbatim** in `## Decision`, then answer it. On
   `reconsider`, the recommendation changes or the reason it survives is
   written down. An unanswered objection is a decision made in the dark.
5. **Record the decision**: the choice, the alternative that lost, and why it
   lost. Then set `status: decided`, or `status: dropped` when the decision was
   not to build.
6. **Mirror the durable part** into `maestro_docs/memory/tech-decisions.md` when
   the choice constrains future work — one line, with a pointer to the design
   folder. Show the diff and wait for approval.

## Test

- Every approach states a cost and the condition under which it wins.
- `## Decision` names one rejected alternative and the reason it lost.
- The devil-advocate verdict is present verbatim, and each of its top risks is
  either accepted in writing or answered.
- `status` is `decided` or `dropped`, never left at `exploring`.
