---
name: 00-onboard
description: Onboard a project into Maestro 5. Detects the stack, recommends and installs the right official Anthropic plugins (LSP, security-guidance, frontend-design, commit-commands...), enables the relevant Maestro plugins, and scaffolds the memory bank. Use to set up Maestro on a new or existing project. Not for updating a single memory file or fixing an existing install (use 04-doctor for that).
argument-hint: detect | official-plugins | maestro-plugins | scaffold
---

# Skill: onboard

Take a project from zero to fully-configured Maestro 5: stack detected, official
plugins installed, Maestro plugins enabled, memory bank scaffolded.

## Actions

| #  | Action             | Role                                                          | Input                |
|----|--------------------|---------------------------------------------------------------|----------------------|
| 01 | `detect-stack`     | Inspect the project and produce a stack profile               | project root         |
| 02 | `official-plugins` | Recommend and install official Anthropic plugins for the stack | stack profile from 01 |
| 03 | `maestro-plugins`  | Enable the relevant Maestro plugins for the stack             | stack profile from 01 |
| 04 | `scaffold`         | Create maestro_docs/ memory bank + CLAUDE.md memory block     | project root         |

Run them in order, `01 → 04`. Each action's `## Test` must pass before the next.
Before running an action, read its file in `actions/`, not only this table.

## Transversal rules

- **Ask before installing anything.** Present the recommended plugin list with
  a one-line justification each, get explicit approval, then install. Never
  install silently.
- **Philosophy rule #8 applies**: recommend official plugins for every
  capability they cover. Maestro plugins are the business layer only.
- **Scopes**: official personal tools (LSP, commit-commands, context7) →
  `--scope user`. Team-shared or project-specific (security-guidance if not
  already active, Maestro plugins) → `--scope project`.
- **Idempotent**: re-running onboard on a configured project must detect what
  exists, skip it, and report "already configured" per item.
- End with a short report: stack detected, plugins installed, files created.
