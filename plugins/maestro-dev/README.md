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
  routed handoff (see docs/BRAINSTORM-SUPERPOWERS.md)
- `04-debug` — reproduce → isolate → cause → fix + regression test; no edit
  before a repro; resumable `debug.md`; side-findings go to `03-ticket`

## Agents

- `executor` (sonnet) — builds validated code, never judges its own work
- `checker` (opus) — judges with evidence, never edits the work
- `m-architect` (opus) — designs structure before code
- `m-devil-advocate` (opus) — argues the strongest case against a plan
  (replaces the human pause in auto mode)
- `m-i18n-checker` (sonnet) — audits diffs for i18n/RTL correctness with
  evidence, never fixes

## References

- `references/expert-postures.md` — domain postures every step adopts
- `references/cognitive-protocols.md` — anti-complacency rules

## Hooks

None. Quality lives in the workflow (Philosophy rules #1-2).
