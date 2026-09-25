# Model policy — the ladder

Goal: the best final quality per token, in that order. Quality comes from the
workflow (plan → implement → tests → review) **and** from the tier that runs
the step where the work is actually decided. Never pay for reasoning a step
does not need; never save on the step that decides the architecture.
**Complexity picks the tier, never length.**

A pin is not overridable. Frontmatter carries exactly one `model:`, and a
dispatch cannot change it — so going up the ladder means dispatching a
**different agent**, never "dispatching X with model: opus". `validate.js`
refuses any text that promises otherwise (PHILOSOPHY rule 5).

## Ladder

| Model | Role | Steps |
|---|---|---|
| `sonnet` | **Orchestrate and run** — session default | driving a skill (`00-sdlc`, `02-implement`), commits, releases, docs and prose, gate runs, rule-driven audits (`m-i18n-checker`) |
| `fable` | **Build and judge** | writing code (`executor`), planning, architecture, brainstorm, debugging, review (`checker`), specs, perf, design review |
| `opus` | **Decide on critical** | `checker-critical` (review of a critical change), `m-deep-analyst` (analysis fable could not settle), `01-security-audit` |

Why the code-writing step is on fable and not sonnet: a feature's local
architecture — module boundaries, abstractions, error handling, what becomes
a shared helper — is decided inside the executor, one file at a time. `01-plan`
on fable protects the shape of the feature; it does not protect those
decisions. A review cannot add architecture that was never there: it can only
send the phase back. Paying one tier more where the code is born is cheaper
than a repair loop, and much cheaper than a rewrite three weeks later.

Why the session stays sonnet: orchestration is dispatching, gating, writing
state files and committing. It carries no design decision — the think-steps
and the agents pin their own tier.

## Escalation

- fable → opus by **dispatching**: `checker-critical` when the change is
  critical (auth, payment, security, concurrency, data migration,
  cross-project contract) or `maestro_docs/gates.json` level ≥ `high`;
  `m-deep-analyst` when `m-analyst` came back inconclusive, or when the
  problem is critical from the start.
- Never escalate because a task is long, big or repetitive — only because it
  is complex or expensive to get wrong. Never ask the user which model to
  use: decide, and say in one line why.
- `01-security-audit` is opus by definition; security is never the cheap path.

## De-escalation

After an opus decision, execution goes back to the `executor` (fable): the
thinking is done and the plan is falsifiable. After a fable analysis,
mechanical follow-up (commit, docs, ticket) runs on the session (sonnet).

## Effort

| Task | Effort |
|---|---|
| trivial (rename, doc line, config value) | `low` |
| normal (feature, test, classic bug) | `medium` |
| complex (design, hard debug, large refactor) | `high` |
| critical | `high` + opus agent |

No over-reasoning: `high` on a CRUD endpoint is waste, not safety. The
`executor` stays on `medium` on purpose — it builds against a plan that was
already reasoned at `high`.

## Context discipline

Small and relevant. Before reading, name the files, modules, dependencies and
tests concerned; read those. When the context grows, summarise (state file,
`maestro-core:03-condense`) instead of carrying the whole history. A dispatch
carries the phase, the objective, the memory references — never the session.

## Fleet (≈ 8 projects in parallel)

- sonnet tasks run in parallel freely.
- One opus dispatch at a time across all projects; heavy fable analyses run
  sequentially. `maestro-dev:00-sdlc auto` never runs two opus dispatches
  concurrently.
- No complex reasoning in parallel just because it is possible.
- Instruction, not a hook (PHILOSOPHY rule #1): the model reads this and
  complies; nothing enforces it.

## How Maestro applies it

| Skill / agent | Model | Effort | Why |
|---|---|---|---|
| session default (`.claude/settings.json`) | sonnet | — | the session orchestrates |
| `00-sdlc`, `02-implement` | sonnet | medium | dispatch, gate, commit — no design decision |
| `maestro-quality:00-quality-gate` | sonnet | low | reads config, runs commands |
| `m-i18n-checker` | sonnet | medium | rule-driven audit |
| `maestro-pm:04-writing` | session | low | prose |
| **`executor`** | **fable** | medium | writes the code and its local architecture |
| `01-plan`, `03-brainstorm` | fable | high | thinking before building |
| `m-architect`, `m-devil-advocate`, `m-analyst` | fable | high | design, challenge, fresh-context analysis |
| `checker` | fable | high | judges with evidence |
| `04-debug` | fable | medium | reproduce → isolate → cause is reasoning; the fix must be surgical |
| `maestro-quality:02-perf-audit` | fable | high | measurement + judgement |
| `maestro-web:02-design-review` | fable | high | visual, UX and RTL judgement |
| `maestro-pm:00-prd`, `02-specs` | fable | — | conception |
| **`checker-critical`** | **opus** | high | critical change: criteria **and** failure modes |
| **`m-deep-analyst`** | **opus** | high | what fable could not settle; critical by nature |
| `maestro-quality:01-security-audit` | opus | high | security is critical by definition |

Force at any time with `/model opus` — the pins above only raise the tier for
the steps that need it, and never lower a model you set for an unpinned step.
