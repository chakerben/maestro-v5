---
name: 00-qa-e2e
description: End-to-end tests of a project the Injaz QA agents cover — Playwright web tests, Maestro mobile.dev flows, the qa/map scenario ↔ test file, reviewing an agent's heal diff, flaky tests, the agents' runbook. Use when writing, mapping or reviewing those tests in Claude Code. Not for unit tests, and not for the security scanners (maestro-security).
argument-hint: "web | mobile | map | heal | flaky | runbook"
---

# Skill: QA end-to-end (the Injaz QA agents)

> **Maestro 5** = this plugin marketplace, the only orchestrator. **Maestro mobile.dev** = the mobile E2E tool
> (`maestro test`, YAML flows). Two different things that share a name — every file of this plugin says which.

Two machines share the work (plan qa-agents-v1, D27):

| In Claude Code, with a human (here) | On the QA Mac Studio, 24/7, non-Claude models |
|---|---|
| scenario libraries (`/injaz-test-scenarios`), `/qa-bootstrap-project` | deterministic Playwright / Maestro mobile.dev runs |
| the `qa/map` file (`/qa-map-scenarios`, `/qa-coverage`) | triage, healing, ticket writing, re-tests |
| reviewing heal diffs (`/qa-heal-review`) | flaky detection, learnings, digests |

**Injaz holds the truth**: the scenario library (`TechTestScenario`, refs like `AUTH-001`), the targets and environments
a project declares, the tickets. A repository holds the tests and `qa/map/<CODE>.scenarios.json`. Coverage is
**computed** from that file, never declared.

## Actions

| #  | Action             | Role                                                              | Input            |
|----|--------------------|-------------------------------------------------------------------|------------------|
| 01 | `playwright-web`   | Write or fix a Playwright test the web lane can run               | spec / scenario  |
| 02 | `maestro-mobile`   | Write or fix a Maestro mobile.dev flow (app, or Safari on iOS)    | flow / scenario  |
| 03 | `scenario-mapping` | Fill or review `qa/map/<CODE>.scenarios.json`                      | repository       |
| 04 | `heal-review`      | Accept or reject a diff the agent's healer proposed                | ticket / diff    |
| 05 | `flaky-policy`     | Decide what an unstable test is and what happens to it             | test / ticket    |
| 06 | `agent-runbook`    | Where things are: Injaz screens, keys, kill switch, costs, logs    | question         |

Each action lives in `${CLAUDE_PLUGIN_ROOT}/skills/00-qa-e2e/actions/NN-name.md`; read only the one the task needs.

## Commands

| Command | Does |
|---|---|
| `/maestro-test-e2e:qa-bootstrap-project` | Resolve this repository to its Injaz project (refuses when there is none or several), then add the missing `qa/` skeleton — never overwrites, never writes a secret |
| `/maestro-test-e2e:qa-map-scenarios` | Propose map entries from the scenario library and the existing tests; a human validates |
| `/maestro-test-e2e:qa-heal-review` | Review one heal diff with action 04 |
| `/maestro-test-e2e:qa-coverage` | Coverage computed from the map: automated / manual / blocked, refs without a test, tests without a ref |

## Transversal rules

- **No secret in a repository**: test accounts are named by their variable (`testAccountRef`), the workstation key
  stays in `~/.config/injaz-qa/.env`. A command that would write one stops.
- **A test names its scenario**: `[REF]` in the Playwright title, the map `flow` path for Maestro mobile.dev. No ref,
  no chain scenario → run → ticket.
- **WebKit on macOS is not iOS Safari** (D11). A sensitive path (login, upload, payment, PWA) that only passes in the
  `Desktop Safari` project is not proven on iPhone: it needs a `qa/safari/` flow (action 02).
- **No third party is a target**: the browsers go through the run's egress proxy (the environment's host + the map's
  `web.allowedHosts`); payment providers are cut whatever the list says. A flow that reaches a paid third party is
  `manual` with mocks.
- **Production is read-only**: Desktop Chrome + `@smoke` only, never a write, never `request-otp`.
- Arabic UI: Western digits, `YYYY/MM/DD`, exact Arabic strings in selectors (escape regex metacharacters).

## Test

- `/maestro-test-e2e:qa-bootstrap-project` in a repository no Injaz project claims writes nothing and says why.
- A test written with action 01 carries `[REF]`, a role / test-id selector, and none of `networkidle`,
  `waitForTimeout`, `test.only`, `test.skip`, `test.fixme`.
- Nothing this skill produces contains a `qa_` key, an `sk-or-` key or a password.
