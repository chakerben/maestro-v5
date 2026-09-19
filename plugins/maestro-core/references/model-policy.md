# Model policy — the ladder

Goal: maximise final quality per token spent. Quality comes from the
workflow (plan → implement → tests → review), not from the most expensive
model everywhere. Never sacrifice quality to save; never pay for reasoning
a task does not need. **Complexity picks the model, never length.**

## Ladder

| Model | Role | When |
|---|---|---|
| `sonnet` | **Execute** — session default | normal features (front/back, API, CRUD, integrations), tests, classic bugs, local refactoring, docs, normal code review, simple migrations, perf without redesign |
| `fable` | **Think** — analyse, plan, judge | complex feature design, comparing architecture approaches, hard-to-reproduce or multi-layer bugs, large refactoring, strategy before a big implementation, a prior sonnet failure |
| `opus` | **Decide** — critical only | major architecture / system redesign, extremely complex bug, important security, concurrency / race / complex perf, a decision spanning several projects, sonnet + fable both failed, final review of a critical or regression-prone change |

Pattern: fable plans → sonnet implements → tests → fable/opus review only
when the change warrants it.

## Escalation

- sonnet → fable when: the task is complex, several approaches compete, the
  reasoning is hard, sonnet is stuck, or the change carries architecture risk.
- fable → opus when: fable's analysis is inconclusive, the change is critical
  (see ladder), or maximum reasoning is required.
- Never escalate because a task is long, big, or repetitive — only because it
  is complex. Never ask the user which model to use: decide, and say in one
  line why when you switch.

## De-escalation

After a fable/opus analysis or plan, come back to sonnet for execution
whenever that does not reduce quality — which is almost always: the thinking
is done, the plan is falsifiable, the executor validates each step.

## Effort

| Task | Effort |
|---|---|
| trivial (rename, doc line, config value) | `low` |
| normal (feature, test, classic bug) | `medium` |
| complex (design, hard debug, large refactor) | `high` |
| critical | `high` + fable/opus |

No over-reasoning: `high` on a CRUD endpoint is waste, not safety.

## Context discipline

Small and relevant. Before reading, name the files, modules, dependencies and
tests concerned; read those. When the context grows, summarise (state file,
`maestro-core:03-condense`) instead of carrying the whole history. A dispatch
carries the phase, the objective, the memory references — never the session.

## Fleet (≈ 8 projects in parallel)

- sonnet tasks run in parallel freely.
- One opus dispatch at a time across all projects; heavy fable analyses run
  sequentially. `maestro-dev:00-sdlc auto` never runs two opus reviews
  concurrently.
- No complex reasoning in parallel just because it is possible.
- Instruction, not a hook (PHILOSOPHY rule #1): the model reads this and
  complies; nothing enforces it.

## How Maestro applies it

| Skill / agent | Model | Effort | Why |
|---|---|---|---|
| session default (`.claude/settings.json`) | sonnet | — | execution is the common case |
| `executor` | sonnet | medium | builds against a falsifiable plan |
| `m-i18n-checker` | sonnet | medium | rule-driven audit |
| `01-plan`, `03-brainstorm` | fable | high | thinking before building |
| `m-architect`, `m-devil-advocate`, `m-analyst` | fable | high | design, challenge, fresh-context analysis |
| `checker` | fable | high | judges with evidence; **opus** when the change is critical or `gates.json` level ≥ high |
| `04-debug` | session (sonnet) | medium | classic bugs; escalates to `m-analyst` (fable), then opus, only when stuck |
| `00-sdlc`, `02-implement` | session (sonnet) | medium | orchestration; think-steps pin their own model |
| `maestro-pm:00-prd`, `02-specs` | fable | — | conception |
| `maestro-quality:01-security-audit` | opus | high | security is critical by definition |
| `maestro-quality:02-perf-audit` | fable | high | opus only for concurrency/race or inconclusive complex perf |
| `maestro-web:02-design-review`, `maestro-pm:04-writing` | session (sonnet) | —/low | normal review, prose |

Force at any time with `/model opus` — the pins above only raise the model
for the steps that need it.
