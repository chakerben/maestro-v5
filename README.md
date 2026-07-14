# Maestro 5

> Business-layer framework for web & mobile development, built on top of the
> official Claude Code plugin ecosystem. RTL/Arabic-native. Workflow-enforced
> quality. Zero runtime bloat.

**7 plugins · 2 hooks total · FR/EN/AR**

## Install

```text
/plugin marketplace add arabiipte/maestro-v5
/plugin install maestro-core@maestro
```

Then in any project:

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
| `maestro-dev` | sdlc, plan, implement, review, TDD, debug + executor/checker agents | 0 |
| `maestro-quality` | Quality gates at commit/review time | 1 (PreToolUse bash-guard) |
| `maestro-mobile` | RN/Expo/Flutter, RTL Arabic, RTL PDF | 0 |
| `maestro-web` | Next.js/Prisma/Clerk stack, UX, design review | 0 |
| `maestro-pm` | PRD, user stories, specs (FR/EN/AR) | 0 |
| `maestro-vcs` | Commits with gates, PRs, releases | 0 |

## Philosophy

Read [PHILOSOPHY.md](PHILOSOPHY.md) — the 8 rules every change is reviewed
against. The short version: **quality belongs in the workflow, not in the
runtime**, and **never rebuild what Anthropic maintains**.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Migration from Maestro v4](docs/MIGRATION-FROM-V4.md)

## License

MIT
