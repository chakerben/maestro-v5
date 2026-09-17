---
name: 05-lean-code
description: Standing rules for every line of code written or reviewed in a Maestro project — the cheapest correct solution wins, changes are surgical, success is verifiable. Applies silently while building; cited by rule name when reviewing. Also answers "simplifie", "c'est trop compliqué", "review for over-engineering", "audit de dette".
argument-hint: "[audit <path>]"
user-invocable: true
effort: medium
---

# Skill: lean-code

> Absorbed from Ponytail (the ladder, the debt marker) and Andrej Karpathy's
> guidelines for LLM coding (think first, simplicity, surgical changes,
> goal-driven execution). Rewritten as Maestro rules; nothing installed.

Most code an assistant writes is code that should not exist: a helper for a
one-liner, a dependency for a stdlib call, an abstraction for a single caller,
a refactor nobody asked for. These rules cut that at the source.

## The ladder — climb only as far as needed

Before writing anything, answer in order and stop at the first rung that works:

1. **Skip** — is the thing needed at all? A request often contains a step the
   user assumed. Say so in one line, then do what remains.
2. **Reuse** — does the codebase already do this? `grep` before writing. The
   second implementation of a thing is a bug, not a feature.
3. **Stdlib / language** — `Intl`, `URL`, `structuredClone`, `Array.prototype`,
   `fetch`, `AbortController`, `crypto.randomUUID()`. No package for what the
   runtime already does.
4. **Platform** — Next.js / Expo / Prisma / Clerk already provide it
   (revalidation, image optimisation, auth middleware, `@@index`). Check
   context7 before assuming they don't.
5. **Installed dependency** — something already in `package.json` covers it.
   Read its docs (context7) rather than adding a sibling.
6. **One-liner** — an inline expression at the call site, no new function.
7. **Build** — only now, and the smallest version that passes the criterion.

Every rung above 7 is announced when it changes the shape of the answer
("stdlib covers this — no new dependency").

## Think before coding

- Restate the goal as a **verifiable criterion** (a command, a test, an
  observable) before touching a file. No criterion → ask one question.
- Name the assumptions. An unstated assumption is where the rework comes from.
- If two approaches exist, name them and pick one with a reason — do not
  build both "to be safe".

## Surgical changes

- Touch what the task names. No drive-by renames, no reformatting of
  untouched lines, no "while I'm here". If something else is wrong, it goes
  to `maestro-pm:03-ticket` or a `// debt:` marker — never into this diff.
- New abstraction only with **≥ 3 callers today**, not "future callers".
- No configuration for a single value. No feature flag for a decided feature.
- Delete what you replace. Dead code is not "kept for reference" — git is.

## Debt marker

Deliberate shortcut → `// debt: <what> — <why now> — <what would fix it>`
(same convention in Python `# debt:` and Dart). Greppable, one line, no
ticket unless the human asks. The checker lists every new `debt:` marker in
its report.

## Non-negotiable exceptions (the ladder never trims these)

Security (authz on every path, input validation at boundaries), accessibility
(labels, focus, contrast), RTL correctness when an `ar` locale exists, and
error states. "Lean" means no ceremony — not no safety.

## `audit <path>` mode

Walk the scope and report, per finding: file:line · rung it should have
stopped at · the smaller version (as a diff sketch) · lines saved. Rank by
lines saved. Never apply — this is a review.

## Test

- Code written under this skill adds no dependency the runtime or an
  installed package already covers, and no function with a single caller
  that fits inline.
- A review under this skill cites the rung by number for every finding.
- No line outside the task's scope changed (`git diff --stat` matches the
  task).
