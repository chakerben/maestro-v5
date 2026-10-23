# Model policy — the ladder

**Complexity picks the tier, never length.** Pay for reasoning only where the
work is decided; never save on the step that decides the architecture.

| Model | Role | Steps |
|---|---|---|
| `sonnet` | orchestrate and run — session default | `00-sdlc`, `02-implement`, `00-quality-gate`, commits, releases, prose, `m-i18n-checker` |
| `fable` | build and judge | **`executor`**, `01-plan`, `03-brainstorm`, `04-debug`, `checker`, `m-architect`, `m-devil-advocate`, `m-analyst`, `02-perf-audit`, `02-design-review`, `00-prd`, `02-specs` |
| `opus` | decide on critical | **`checker-critical`**, **`m-deep-analyst`**, `01-security-audit` |

## What enforces it

A frontmatter `model:` is a **default**: Claude Code resolves a dispatch's own
`model` parameter before it. The pin is a pin only with
**`Agent(model:*)` in the project's `permissions.deny`** — written by
`00-onboard` scaffold 4b and `fleet-apply.sh --settings`, reported by
`04-doctor`, required by `validate.js`. With it, a dispatch that names a model
is refused; going up the ladder means dispatching a **different agent**
(`checker-critical`, `m-deep-analyst`), whose criteria are the point.

## Escalation and return

- Critical change (auth, payment, security, concurrency, data migration,
  cross-project contract) or `maestro_docs/gates.json` level ≥ `high` →
  `checker-critical` instead of `checker`.
- `m-analyst` inconclusive, or a problem critical from the start →
  `m-deep-analyst`; a critical problem skips `m-analyst`.
- `01-security-audit` is opus by definition.
- Never escalate because a task is long or repetitive. Never ask the user
  which model; decide, say why in one line.
- After an opus decision, execution returns to the `executor` (fable); after
  a fable analysis, mechanical follow-up runs on the session (sonnet).

## Effort

`low` trivial (rename, config value) · `medium` normal (feature, classic bug;
the `executor` stays here — it builds against a plan reasoned at `high`) ·
`high` complex (design, hard debug, large refactor) · critical = `high` +
an opus agent. `high` on a CRUD endpoint is waste, not safety.

## Context

Name the files, modules and tests concerned before reading; read those.
Audits run with `context: fork` (the reading stays out of the session, the
report comes back). A dispatch carries the phase, the objective and the
memory references — never the session history. When the context grows,
summarise into the state file (`maestro-core:03-condense`) instead of
carrying it.

## Fleet (≈ 8 projects in parallel)

Sonnet tasks in parallel freely; one opus dispatch at a time across projects;
heavy fable analyses in sequence. Instruction, not a hook (rule #1).

Force at any time with `/model opus`: pins only raise the tier for the steps
that need it and never lower a model you set for an unpinned step. The
per-skill pins (`03-condense` low, `03-motion` medium, the audits high) are in
their frontmatter — the frontmatter is the record, not this page.
