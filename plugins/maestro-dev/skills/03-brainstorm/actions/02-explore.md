# 02 - Explore

The one-question loop.

## Input

The unknowns from `01-frame`, in order.

## Output

`design.md` `## Journal` grown by one entry per exchange, and a stop reason.

## Process

Repeat until the stop condition holds:

1. **Ask the top unknown**, as one question, in the user's language. Give the
   two or three answers you consider most likely as a multiple choice when they
   exist — a choice is faster to answer than an open field, and the options
   reveal what you already understood. Add "autre chose" implicitly by leaving
   the question open.
2. **Wait.** The turn ends with the question.
3. **Write the entry** to `## Journal`:
   ```
   ### Q<n> — <la question, telle que posée>
   Réponse : <la réponse, telle que donnée>
   Change : <ce que cette réponse ferme, ouvre, ou déplace>
   ```
   `Change:` is the load-bearing line. If it reads "rien", the question was not
   shape-changing and the next one should come from higher up the list.
4. **Choose the next question from what the answer changed**, not from the
   original list read top to bottom. A list read in order is a questionnaire;
   the point of asking one at a time is that answer three makes question five
   pointless and question nine urgent.
5. **Read, don't ask, whenever the codebase can answer.** Between two questions,
   open the file. Record it in `## Contexte lu`.

## Stop condition

Stop when no remaining unknown would change the shape of the solution. Write in
`## Inconnues laissées ouvertes` the ones you are leaving open, each with the
reason ("dépend de la volumétrie réelle", "tranché à l'implémentation").

An empty `## Inconnues laissées ouvertes` on a non-trivial subject means the
list was not examined — go back and name at least what could still surprise.

## Test

- Every `### Q<n>` heading contains exactly one question mark.
- Every entry has a `Change :` line.
- No two questions were asked in the same turn.
- `## Inconnues laissées ouvertes` exists and each line carries a reason.
