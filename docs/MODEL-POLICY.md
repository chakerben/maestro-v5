# Model policy — Sonnet orchestrates, Fable builds and judges, Opus decides

Source of truth for the model: `plugins/maestro-core/references/model-policy.md`
(what the skills and agents read). This page is the human version, and it
records why 5.13.0 changed the ladder.

## Why it changed

5.12.1 read "Sonnet executes, Fable thinks, Opus only when critical", and the
code matched that sentence: `executor` on sonnet, the session default written
to sonnet by `00-onboard`, and 21 of 33 skills declaring no model at all — so
running on the session, so sonnet. Fable planned and judged; opus appeared
exactly once, in `01-security-audit`.

Two problems with that, found by auditing the pins against the doc:

1. **The step where code quality is decided was the cheapest step.** A
   feature's global shape is protected by `01-plan` (fable). Its *local*
   architecture is not: module boundaries, what becomes a shared helper, how
   errors propagate, what the abstraction is — those are decided inside the
   executor, file by file. A reviewer can reject a structure; it cannot add
   one that was never written. The executor was also on `effort: medium`, so
   the tier and the reasoning were both the lowest in the framework, at the
   one place whose output is the deliverable.
2. **Three escalations in this document could not happen.** It said `checker`
   runs on opus for a critical change, `04-debug` re-dispatches `m-analyst`
   on opus, `02-perf-audit` re-runs a finding on opus. Frontmatter carries
   exactly one `model:`, and a dispatch cannot override it — so `checker` was
   always fable, and the opus rung existed only as a sentence. A fourth
   instance was in `m-architect`. That is precisely what PHILOSOPHY rule 5
   forbids: a rule described as guaranteed when it is only requested, which
   stops you checking.

## The ladder (5.13.0)

| Model | Job | Steps |
|---|---|---|
| **Sonnet** | orchestrate and run — session default | `00-sdlc`, `02-implement`, `00-quality-gate`, commits, releases, docs, prose, `m-i18n-checker` |
| **Fable** | build and judge | **`executor`**, `01-plan`, `03-brainstorm`, `04-debug`, `checker`, `m-architect`, `m-devil-advocate`, `m-analyst`, `02-perf-audit`, `02-design-review`, `00-prd`, `02-specs` |
| **Opus** | decide on critical | **`checker-critical`**, **`m-deep-analyst`**, `01-security-audit` |

The session stays on sonnet on purpose: orchestration is dispatching, gating,
writing state files and committing — it carries no design decision. What
moved up is the work, not the session.

Escalating means **dispatching a different agent**, never overriding a model:

- `checker-critical` (opus) replaces `checker` when the change is critical
  (auth, payment, security, concurrency, data migration, cross-project
  contract) or `maestro_docs/gates.json` is at `high`/`paranoid`. It runs the
  criteria pass, then a failure-mode pass: unauthenticated reach, another
  tenant's id, the second or concurrent or retried call, the halfway state and
  its rollback, attacker-controlled input, money and rounding.
- `m-deep-analyst` (opus) is dispatched when `m-analyst` (fable) came back
  inconclusive, or when the problem is critical from the start. It reads the
  previous analysis and attacks the assumption that one did not question.
  `04-debug` and `02-perf-audit` both route their opus step here, and
  `m-architect` routes a critical architecture decision here.

## What it costs

The executor is dispatched 5 to 7 times per feature (one per phase, plus
repair loops), so moving it from sonnet to fable is the real bill of this
release — roughly the cost of the build phase, one tier up. The two opus
agents are rare by construction: a critical change or a stuck analysis, one
opus dispatch at a time across the fleet. Effort stayed at `medium` on the
executor deliberately: it builds against a plan already reasoned at `high`,
and `high` on a CRUD endpoint is waste, not safety.

The trade is explicit: a repair loop costs an executor dispatch plus a review;
a structure discovered to be wrong three weeks later costs a rewrite. This
release buys the second one down and accepts a higher unit price on the first.

## What enforces it

`scripts/validate.js`, in `npm test`:

- every agent declares a model from the ladder;
- an opus pin must say `critical` or `security` in its body;
- the think-steps (`01-plan`, `03-brainstorm`, `m-architect`, `m-analyst`,
  `checker`) are on fable;
- the opus rung — `checker-critical`, `m-deep-analyst`, `01-security-audit` —
  **must exist and must be pinned to opus**;
- `executor` must be fable or above;
- **no text may promise an opus dispatch that cannot happen**: a body saying
  "dispatch X with model: opus" is refused, and any file that mentions opus
  must name an agent that is really pinned to it. A doc may quote the
  forbidden phrasing in order to forbid it (the negation has to sit in the
  same clause). Six regression cases in `scripts/tests/validate.test.sh`.

## How you work with it

- **Keep the session on sonnet**: `/model sonnet`, or accept onboard's offer
  to write `"model": "sonnet"` into `.claude/settings.json`. The agents raise
  the tier where it matters; raising the session raises it everywhere,
  including commits and docs.
- **You never choose per step.** The pins do it, and each step says in one
  line which agent ran and why when it goes up.
- **Forcing stays yours**: `/model opus` for the session. Pins only raise the
  tier for the steps that need it; they never lower a model you set for an
  unpinned step.
- **Fleet rule** (instruction, not a hook): one opus dispatch at a time across
  projects, heavy fable analyses in sequence, sonnet work in parallel as you
  like. `00-sdlc auto` never runs two opus dispatches at once.
