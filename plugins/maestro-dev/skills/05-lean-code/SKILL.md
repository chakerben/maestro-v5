---
name: 05-lean-code
description: Standing rules for every line of code written or reviewed in a Maestro project — the cheapest correct solution wins, changes are surgical, success is verifiable. Applies silently while building; cited by rule name when reviewing. Also answers "simplifie", "c'est trop compliqué", "review for over-engineering", "audit de dette".
argument-hint: "[audit <path>]"
user-invocable: true
effort: medium
---

# Skill: lean-code

> Ponytail's ladder + Karpathy's guidelines, as Maestro rules. Preloaded in
> every executor/checker/architect dispatch — kept short on purpose.

## The ladder — climb only as far as needed

Before writing anything, answer in order and stop at the first rung that works:

1. **Skip** — needed at all? Say so in one line, do what remains.
2. **Reuse** — `grep` first; the second implementation of a thing is a bug.
3. **Stdlib** — `Intl`, `URL`, `structuredClone`, `fetch`, `crypto.randomUUID()`…
4. **Platform** — Next/Expo/Prisma/Clerk already do it (check context7 first).
5. **Installed dep** — something in `package.json` covers it; read its docs.
6. **One-liner** — inline at the call site, no new function.
7. **Build** — only now, the smallest version that passes the criterion.

Announce the rung when it changes the answer ("stdlib covers this").

## Think before coding

- Restate the goal as a **verifiable criterion** (command, test, observable)
  before touching a file. No criterion → one question.
- Name the assumptions. Two approaches → name both, pick one with a reason.

## Surgical changes

- Touch what the task names. No drive-by renames, no reformatting untouched
  lines, no "while I'm here" — that goes to `03-ticket` or a `debt:` marker.
- New abstraction only with **≥ 3 callers today**. No config for one value.
- Delete what you replace; git is the reference, not dead code.

## Debt marker

Deliberate shortcut → `// debt: <what> — <why now> — <fix>` (Python `# debt:`).
One line, greppable; the checker lists every new one.

## Non-negotiable exceptions (the ladder never trims these)

Security (authz every path, validation at boundaries), accessibility, RTL
when `ar` exists, error states. Lean means no ceremony — not no safety.

## `audit <path>` mode

Per finding: file:line · rung it should have stopped at · smaller version
(diff sketch) · lines saved. Ranked by lines saved. Never applied.

## Test

- Code written under this skill adds no dependency the runtime or an
  installed package already covers, and no function with a single caller
  that fits inline.
- A review under this skill cites the rung by number for every finding.
- No line outside the task's scope changed (`git diff --stat` matches the
  task).
