# maestro-security

> **Maestro 5** = this plugin marketplace, the only orchestrator. **Maestro mobile.dev** = the mobile E2E tool
> (`maestro test`). Two things, one name.

The Claude Code side of the Injaz QA security agent (agent B, plan `qa-agents-v1`): what each defensive scanner does,
what is in scope, the licences, and how a human triages a critical finding. **Defensive only**: no exploitation, no
active scan, no third-party target.

| | |
|---|---|
| Skill | `00-qa-security` — actions `01-defensive-scanners`, `02-expo-bundle`, `03-passive-checks`, `04-scope-and-licences`, `05-finding-triage` |
| Command | `qa-security-triage` |

**Install** in a project the QA agents cover: `/plugin install maestro-security@maestro` (project scope).

One router rather than five skills for the same reason as `maestro-test-e2e`: the skill index budget.
