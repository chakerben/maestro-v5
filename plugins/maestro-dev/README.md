# maestro-dev

The development pipeline.

## Skills

- `00-sdlc` — full flow: spec → plan → implement → review → ship.
  Interactive by default; `auto` runs unattended to completion with hard
  stops (blocked, gate red x3, payment/destructive, credentials).
- `01-plan` — gather → explore → phased plan with resumable frontmatter state
- `02-implement` — phase loop: fresh executor context per phase, assertion
  gates, one commit per phase, resume support
- `03-brainstorm` — one question at a time, journal, devil-advocate pass,
  routed handoff (`design.md` with `status: exploring | decided | dropped`)
- `04-debug` — reproduce → isolate → cause → fix + regression test; no edit
  before a repro; resumable `debug.md`; side-findings go to `03-ticket`
- `05-lean-code` — the ladder (skip → reuse → stdlib → platform → installed dep
  → one-liner → build), surgical changes, `debt:` markers; preloaded in the
  executor, checker and architect
- `06-protocols` — the 6 anti-complacency rules (evidence, confidence,
  falsifiable plan, disagree once, no silent scope change, completion
  honesty, model ladder); not user-invocable, preloaded in all 8 agents

## Agents

Pinned per the model ladder (`maestro-core references/model-policy.md`):

- `executor` (**fable**) — builds validated code, never judges its own work.
  Fable and not sonnet since 5.13.0: a feature's local architecture (module
  boundaries, abstractions, error handling) is decided here, and a review
  cannot add a structure that was never written
- `checker` (fable) — judges with evidence, never edits the work
- `checker-critical` (**opus**) — the same, for a critical change (auth,
  payment, security, concurrency, data migration, cross-project) or gate level
  high/paranoid: adds a failure-mode pass (unauthenticated reach, cross-tenant
  id, concurrent or retried call, halfway state and its rollback, attacker-
  controlled input, money and rounding). A separate agent, because a pinned
  model cannot be overridden by a dispatch
- `m-architect` (fable) — designs structure before code
- `m-devil-advocate` (fable) — argues the strongest case against a plan
  (replaces the human pause in auto mode)
- `m-analyst` (fable) — fresh-context analysis of a bug or a choice the
  session is stuck on; returns cause/approach + a falsifiable plan, never
  implements. Says so explicitly when inconclusive
- `m-deep-analyst` (**opus**) — the rung above: dispatched when `m-analyst`
  came back inconclusive, or when the problem is critical from the start
  (security, concurrency/race, data loss, cross-project decision). States the
  interleaving, not "a race"; returns cause or decision + falsifiable plan
- `m-i18n-checker` (sonnet) — audits diffs for i18n/RTL correctness with
  evidence, never fixes

## References

- `references/expert-postures.md` — domain postures every step adopts
- `references/cognitive-protocols.md` — pointer to `06-protocols`

## Hooks

None. Quality lives in the workflow (Philosophy rules #1-2).
