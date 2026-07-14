---
name: 04-doctor
description: Verify the health of a Maestro install in the current project — plugins enabled, hooks compliant, memory bank coherent, and NO leftovers from Maestro v4 or third-party orchestrators (claude-flow, ruv-swarm). Use after a migration, when something feels broken, or as a periodic checkup. Not for first-time setup (00-onboard).
argument-hint: check | fix
---

# Skill: doctor

The coherence checker. Its most important job: guarantee the v4 runtime
machinery that caused RAM crashes never comes back.

## Actions

| #  | Action  | Role                                              | Input        |
|----|---------|---------------------------------------------------|--------------|
| 01 | `check` | Full diagnostic, findings by severity             | project root |
| 02 | `fix`   | Apply safe corrections, each approved             | check report |

Run `check` first, always. `fix` only consumes a check report from this
session. Before running an action, read its file in `actions/`.
