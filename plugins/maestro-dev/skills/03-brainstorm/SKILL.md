---
name: 03-brainstorm
description: Use when the request names a problem but not a solution, when two or more approaches are plausible and the trade-off has not been made, when the ask contains "je pense à", "comment on ferait", "quelle est la meilleure façon", "est-ce qu'on devrait", or when a plan would be guesswork because the shape of the thing is still open. Not for a request that already states its objective and acceptance criteria, not for product framing with users and metrics, not for diagnosing behaviour that already exists.
effort: high
argument-hint: "<l'idée, en une phrase>"
---

# Skill: brainstorm

Turn an open idea into a decision that can be planned against. One question at a
time, each answer written down, ending in a recorded decision — or in a recorded
"don't build this".

## Actions

| #  | Action    | Role                                                        | Input           |
|----|-----------|-------------------------------------------------------------|-----------------|
| 01 | `frame`   | Resolve the task folder, restate the problem, list unknowns  | the request     |
| 02 | `explore` | The one-question loop; every answer lands in the journal      | framed unknowns |
| 03 | `decide`  | 2–3 approaches, devil-advocate pass, record the decision      | journal         |
| 04 | `handoff` | Write `design.md`, name exactly one next step                 | decision        |

Run `01 → 04`. Before running an action, read its file in `actions/`.

## The off-ramp (read this before action 01)

Some requests do not need this skill, and forcing them through it wastes the
user's attention and teaches them to route around the skill next time.

Go straight to the off-ramp when **all three** hold: the objective is already
one sentence, only one reasonable approach exists, and the change touches code
whose conventions are already recorded. Say so in one line — "une seule approche
raisonnable ici, je passe au plan" — and hand off to `maestro-dev:01-plan`.

Everything else runs the four actions, at a size proportional to the question. A
brainstorm can be three questions and four lines of `design.md`.

## Binding rules

**Ask one question. Wait for the answer. Write it to the journal. Choose the
next question from what that answer changed.** A question that could have been
predicted before the previous answer belongs in the same turn as its predecessor
— which means it was not one question.

**Every claim about the codebase is read before it is stated.** Open the file,
quote the line. The journal records what was read, not what was assumed.

**Unknowns you decide to leave open are listed by name.** The stop condition is
falsifiable: stop when no remaining unknown would change the shape of the
solution, and write down the ones you are leaving open anyway.

**The decision names the alternative that lost, and why.** A decision with no
rejected alternative is a preference wearing a decision's clothes.

**Adopt the domain's expert posture**
(`${CLAUDE_PLUGIN_ROOT}/references/expert-postures.md`) and apply protocols
rule 2 (`${CLAUDE_PLUGIN_ROOT}/skills/06-protocols/SKILL.md`) — state
confidence, name the specific unknown rather than smoothing over it.

**When the project has an `ar` locale**, the market questions are asked
unprompted: numerals arab or latn, Hijri or Gregorian, who reads this in Arabic
and on what device. These are shape-changing questions, not polish.

## Where the work lands

`maestro_docs/tasks/<yyyy_mm_dd>_<slug>/design.md`, with frontmatter
`status: exploring | decided | dropped`. The same folder the rest of the pipeline
uses, so a brainstorm interrupted at question four resumes at question five.
