# maestro-test-e2e

> **Maestro 5** = this plugin marketplace, the only orchestrator. **Maestro mobile.dev** = the mobile E2E tool
> (`maestro test`). Two things, one name.

The Claude Code side of the Injaz QA agents (plan `qa-agents-v1`): writing and mapping the end-to-end tests the 24/7 QA
machine runs, and reviewing what it proposes. One router skill, four commands, three scripts.

| | |
|---|---|
| Skill | `00-qa-e2e` — actions `01-playwright-web`, `02-maestro-mobile`, `03-scenario-mapping`, `04-heal-review`, `05-flaky-policy`, `06-agent-runbook` |
| Commands | `qa-bootstrap-project`, `qa-map-scenarios`, `qa-heal-review`, `qa-coverage` |
| `bin/qa-resolve-repo` | which Injaz project this repository belongs to (`GET /api/qa-worker/resolve-repo`, read-only workstation key) |
| `bin/qa-coverage` | coverage computed from `qa/map/<CODE>.scenarios.json`, no network |
| `bin/qa-set-workstation-key` | stores the workstation key, read hidden (or from a pipe), never from an argument |

**Install** in a project the QA agents cover: `/plugin install maestro-test-e2e@maestro` (project scope).

**Setup once per workstation**: in Injaz › الإعدادات › وكلاء الجودة › الأجهزة, create a key of kind «محطة مطوّر
(قراءة فقط)»; store it with `qa-set-workstation-key` (on the Bash PATH once the plugin is enabled; hidden input, never an argument) in `~/.config/injaz-qa/.env` (mode 600); `--url https://injaz-staging.vercel.app` for staging. It can only
resolve a repository to its project — no job, no write. `INJAZ_QA_URL` in the same file points at staging when needed.

**Fleet**: `scripts/fleet-apply.sh --qa-bootstrap --dry-run --all` lists every project and what the bootstrap would do.

Why one router and not eleven skills: the Maestro skill index has a hard budget (11 000 characters for every skill's
description, paid each session); a router costs one description and loads an action only when it is needed.
