# Maestro 5

> Business-layer framework for web & mobile development, built on top of the
> official Claude Code plugin ecosystem. RTL/Arabic-native. Workflow-enforced
> quality. Zero runtime bloat. Sonnet orchestrates, Fable builds and judges,
> Opus decides on critical.

**7 plugins · 33 skills · 8 agents · 2 hooks total · FR/EN/AR**

## Why the constraints

The version before this one shipped 14 lifecycle hooks that ran typecheck, tests
and formatting after every single edit, stacked with third-party orchestrators.
On 13 July 2026 that produced 33 GB of Node RAM on a 24 GB laptop, Jetsam kills
and full system freezes. Maestro 5 was rebuilt around one sentence:

> **Quality belongs in the workflow, not in the runtime.**

Hence two hooks in the entire framework, both cheap and fail-open; hence nothing
runs automatically after an edit. Each of the eight rules in
[PHILOSOPHY.md](PHILOSOPHY.md) is the scar of a specific failure, and `npm test`
— nine checks, 219 cases — refuses a change that breaks one.

## Install

```text
/plugin marketplace add chakerben/maestro-v5
/plugin install maestro-core@maestro
```

Then in any project (or on the whole fleet: `scripts/fleet-apply.sh --settings --doctor --all`):

```text
/maestro-core:00-onboard
```

Onboard detects your stack, recommends the right **official Anthropic plugins**
(LSP, security-guidance, frontend-design, commit-commands, github, context7,
expo, figma…), installs the relevant Maestro plugins, and scaffolds the
project memory bank.

## Plugins

| Plugin | Purpose | Hooks |
|---|---|---|
| `maestro-core` | Onboarding, memory bank, CLAUDE.md gardener, condense, doctor | 1 (SessionStart memory-sync) |
| `maestro-dev` | brainstorm, sdlc, plan, implement, debug, lean-code, protocols + executor/checker/m-architect/m-devil-advocate/m-analyst/m-i18n-checker agents | 0 |
| `maestro-quality` | Quality gates at commit/review time | 1 (PreToolUse bash-guard) |
| `maestro-mobile` | RN/Expo + Flutter standards, RTL Arabic (web/RN/Flutter), RTL PDF (+ ZATCA), store release | 0 |
| `maestro-web` | Next.js/Prisma/Clerk stack, UX, design review, motion (GSAP+Lenis, RTL-safe) | 0 |
| `maestro-pm` | PRD, user stories, specs (FR/EN/AR), tickets → Trello, writing rules (anti-slop, AR register) | 0 |
| `maestro-vcs` | Commits with gates (executable secrets scan), PRs, releases, one-worktree-per-branch | 0 |

## What this is, honestly

A **business layer**, not a platform competitor: rule #8 says never rebuild what
Anthropic maintains, and `00-onboard` recommends the official plugin whenever one
exists.

**Opinionated**: Next.js App Router, Prisma/PostgreSQL, Clerk, Zod and Tailwind on
the web; Expo or Flutter on mobile. Deviating is allowed and gets recorded in
`tech-decisions.md`.

**Built for the Arabic market**, Saudi first. RTL correctness, the six Arabic
plural categories, Hijri dates, SAR rendering, Arabic PDF and ZATCA are not an
afterthought here — they are why the framework exists.

**Not** a general-purpose agent harness, not an orchestrator, and it does not want
to own your session.

## Philosophy

Read [PHILOSOPHY.md](PHILOSOPHY.md) — the 8 rules every change is reviewed
against. The short version: **quality belongs in the workflow, not in the
runtime**, and **never rebuild what Anthropic maintains**.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Model policy](docs/MODEL-POLICY.md) — Sonnet orchestrates, Fable builds and judges, Opus decides on critical; the pins, what enforces them, and what it costs
- [Audit 5.10.0](docs/AUDIT-5.10.0.md) — independent deep pass, 30 findings, closed in 5.11.0
- [Audit 5.9.1](docs/AUDIT-5.9.1.md) — independent adversarial pass on the day's six releases; 17 findings, all closed in 5.9.2
- [Performance & token audit 5.9.0](docs/PERF-AUDIT-5.9.0.md) — what a session and a dispatch cost, and the budget guard
- [Tooling audit 2026-09](docs/TOOLING-AUDIT-2026-09.md) — 25 TikTok-famous tools, what was absorbed, what was rejected and why
- [Audit 5.5.0](docs/AUDIT-5.5.0.md) — what was found, what was fixed in 5.6.0
- [Migration from Maestro v4](docs/archive/MIGRATION-FROM-V4.md) (archived — done in July 2026)

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request: it states
the gate (`npm test`), the two shapes a skill may take, the agent rules, and what
will be refused — a third hook, runtime tooling on a tool event, a `dependencies`
field, or a second framework layered on top.

## Requirements

Claude Code CLI · Node 20+ · macOS or Linux (the scripts are bash 3.2 compatible).

## License

MIT — see [LICENSE](LICENSE).
