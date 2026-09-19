---
description: Discover Maestro capabilities — the menu of skills, agents, and commands, organized by what you want to do. Optional filter argument (e.g. /maestro mobile).
argument-hint: "[category: setup | dev | quality | mobile | web | pm | vcs | context]"
---

Show the Maestro 5 capability menu, filtered by `$ARGUMENTS` if given.

Present it grouped by INTENT (what the user wants to do), not by plugin:

**Getting started**
- Set up Maestro on this project → `maestro-core:00-onboard`
- Check install health / after migration → `maestro-core:04-doctor`

**Building**
- Idea still open, several approaches → `maestro-dev:03-brainstorm`
- Take a feature from idea to shipped → `maestro-dev:00-sdlc` (say `auto` for unattended)
- Plan before building → `maestro-dev:01-plan`
- Implement an existing plan → `maestro-dev:02-implement`
- Something that exists is broken → `maestro-dev:04-debug`
- Independent review before ship → agent `checker`
- Challenge a decision → agent `m-devil-advocate`
- Design architecture / DB schema → agent `m-architect`
- "Simplifie" / too complex / debt audit → `maestro-dev:05-lean-code` (always on while building)

**Context & memory**
- Refresh project memory from the codebase → `maestro-core:01-memory`
- Context feels bloated / rules conflict → `maestro-core:02-gardener`
- Terse output mode → `maestro-core:03-condense` (invoke explicitly: `/maestro-core:03-condense` — not routed by description)
- Any prose a human reads (README, PR, client message, AR/FR/EN) → `maestro-pm:04-writing`

**Quality & delivery**
- Commit with gates + secret detection → `maestro-vcs:00-commit`
- Deep security audit → `maestro-quality:01-security-audit`
- Performance audit → `maestro-quality:02-perf-audit`
- Gate level config → `maestro-quality:00-quality-gate`

**Mobile / Web / PM**
- RN/Expo standards → `maestro-mobile:00-mobile-standards` · Flutter → `04-flutter-standards`
- Arabic RTL i18n (or `audit`) → `maestro-mobile:01-rtl-i18n`
- Arabic PDF generation → `maestro-mobile:02-pdf-rtl`
- Stack enforcement → `maestro-web:00-web-standards` · UX → `01-ux-standards` · Review a screen → `02-design-review` · Landing motion → `03-motion`
- PRD → `maestro-pm:00-prd` · Stories → `01-user-stories` · Specs → `02-specs`
- A finding must go to the team, not be fixed now → `maestro-pm:03-ticket`
- Submit a mobile build to the stores → `maestro-mobile:03-store-release`

**Delivery**
- Open a PR → `maestro-vcs:01-pull-request` · Cut a release → `maestro-vcs:02-release`
- Repo shared with another session → `maestro-vcs:03-worktree` (one branch, one worktree)

End with: "You never need this menu: the `<maestro_routing>` block in CLAUDE.md
routes plain words to the right skill. Describe what you want in plain words — the right skill triggers
automatically from its description. This menu is just the map."
