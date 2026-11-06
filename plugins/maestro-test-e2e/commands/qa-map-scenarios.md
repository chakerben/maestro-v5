---
description: Propose qa/map/<CODE>.scenarios.json entries from the Injaz scenario library and the tests already in the repository, then write only what a human validates.
argument-hint: "[ref prefix, e.g. AUTH]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

> **Maestro 5** = this plugin marketplace. **Maestro mobile.dev** = the mobile E2E tool. Different things.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/00-qa-e2e/actions/03-scenario-mapping.md` and follow it.
2. No `qa/map/*.scenarios.json` → stop: run `/maestro-test-e2e:qa-bootstrap-project` first.
3. Limit the proposal to the refs starting with `$ARGUMENTS` when given.
4. Show the proposal grouped by status (automated / manual / blocked), one line per ref with its file or reason, and ask
   the human which groups to accept. Write only the accepted entries; never drop an entry a human set.
5. Finish with `"${CLAUDE_PLUGIN_ROOT}/bin/qa-coverage"` and show its summary.
