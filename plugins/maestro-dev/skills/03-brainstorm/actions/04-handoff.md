# 04 - Handoff

Close the design and name exactly one next step.

## Input

`design.md` with `status: decided` or `status: dropped`.

## Process

1. **Self-review the document** before showing it. Scan for: a `<placeholder>`
   left in place, a journal entry whose `Changes:` contradicts the decision, an
   approach mentioned in the decision but absent from `## Approaches`, a claim
   about the codebase with no path. Fix inline, do not narrate the fixes.
2. **Route on what the brainstorm actually surfaced** — one destination, named
   explicitly:

   | What the journal is mostly about | Next step |
   |---|---|
   | Who this serves, what changes for them, how success is measured | `maestro-pm:00-prd` |
   | Data model, contracts, integration points, structural risk | `maestro-pm:02-specs`, or agent `m-architect` |
   | How to build it, in what order | `maestro-dev:01-plan` |
   | Decision was **do not build** | stop; `status: dropped` is the deliverable |

   Naming two next steps means the routing question was not answered — pick the
   one the *unresolved* work belongs to.
3. **Hand off with the path, not the content.** The next skill reads
   `design.md` itself. Pasting the design into the handoff puts it in context
   twice and it stays there for the rest of the session.
4. **Report in five lines maximum**: the decision, the alternative rejected, the
   devil-advocate verdict, the unknowns left open, the next step and its path.

## Test

- `design.md` contains no `<placeholder>` and no unresolved contradiction.
- Exactly one next step is named, with the path to the design folder.
- The handoff passed a path, not the design text.
- A `dropped` design states what would have to change for the answer to flip.
