# Model policy — Sonnet executes, Fable thinks, Opus only when critical

Source of truth for the model: `plugins/maestro-core/references/model-policy.md`
(what the skills and agents read). This page is the human version.

## Why

Across a fleet of ~8 projects, the expensive model everywhere is the wrong
default: most of a developer's day is CRUD, tests, classic bugs and local
refactoring, and quality on those comes from the workflow — plan → implement
→ tests → review — not from the reasoning tier. Paying the expert rate for
execution buys nothing; skipping the expert on a hard design costs a rewrite.
So Maestro pins the model per step, by **complexity, never by length**, and
aims at the best final quality per token.

## The ladder

| Model | Job | Typical |
|---|---|---|
| **Sonnet** | execute — the session default | features, API, CRUD, integrations, tests, classic bugs, local refactoring, docs, normal review, simple migrations |
| **Fable** | think — analyse, plan, judge | complex feature design, comparing architectures, multi-layer or hard-to-reproduce bugs, large refactoring, strategy before a big build, after a Sonnet failure |
| **Opus** | decide — critical only | major architecture, system redesign, extremely complex bug, important security, concurrency/race, cross-project decision, Sonnet + Fable both failed, final review of a critical change |

Escalate Sonnet → Fable when the task is complex, several approaches compete,
Sonnet is stuck, or there is architecture risk. Fable → Opus when Fable is
inconclusive, the change is critical, or maximum reasoning is required. After
a Fable/Opus analysis, execution goes **back to Sonnet**.

Effort follows the same idea: trivial → `low`, normal → `medium`, complex or
critical → `high`. No over-reasoning on a CRUD endpoint.

## What Maestro pins

| Step | Model | Effort |
|---|---|---|
| session default (set by onboard in `.claude/settings.json`) | sonnet | — |
| `executor`, `m-i18n-checker` | sonnet | medium |
| `maestro-dev:01-plan`, `03-brainstorm` | fable | high |
| `m-architect`, `m-devil-advocate`, `m-analyst` | fable | high |
| `checker` | fable, **opus** when the change is critical or `gates.json` level ≥ high | high |
| `maestro-dev:04-debug` | session (sonnet); `m-analyst` (fable) when stuck, opus if still inconclusive or critical | medium |
| `maestro-dev:00-sdlc`, `02-implement` | session (sonnet) — the think-steps pin their own | medium |
| `maestro-pm:00-prd`, `02-specs` | fable | — |
| `maestro-quality:01-security-audit` | opus | high |
| `maestro-quality:02-perf-audit` | fable; opus only for concurrency/race or inconclusive complex perf | high |
| `maestro-web:02-design-review`, `maestro-pm:04-writing` | session (sonnet) | — / low |

`scripts/validate.js` checks the pins: every agent declares a model, an opus
pin must state `critical` or `security` in its body, and the think-steps
(`01-plan`, `03-brainstorm`, `m-architect`, `m-analyst`, `checker`) are on
fable.

## How you work with it

- **Set the session to Sonnet**: `/model sonnet`, or accept onboard's offer to
  write `"model": "sonnet"` into `.claude/settings.json` (never overwrites an
  existing value). `maestro-core:04-doctor` flags a session default that is
  not sonnet.
- **You never choose per step.** The skills and agents pin the model where
  thinking is needed and say in one line why when they switch ("checker on
  opus: gate level high").
- **When Maestro goes up**: plan and brainstorm run on Fable; the checker
  runs on Opus for auth, payment, security, concurrency, data migration,
  cross-project changes, or when `maestro-quality:00-quality-gate` is at
  `high`/`paranoid`; `04-debug` spawns `m-analyst` (Fable) when the cause is
  not found after isolation, and re-dispatches it on Opus only if that is
  inconclusive or the bug is critical.
- **Forcing is always possible**: `/model opus` for the session stays yours.
  The pins only raise the model for the steps that need it; they never lower
  a model you set explicitly for an unpinned step.
- **Fleet rule** (instruction, not a hook): one Opus dispatch at a time across
  projects, heavy Fable analyses in sequence, Sonnet tasks in parallel as
  you like. `00-sdlc auto` never runs two Opus reviews at once.
