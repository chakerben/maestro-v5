---
description: Scenario coverage of this repository computed from qa/map — automated / manual / blocked, library refs without an entry, tests and flows without an entry, broken entries. Read-only.
argument-hint: "[--json]"
allowed-tools: Bash, Read
---

> **Maestro 5** = this plugin marketplace. **Maestro mobile.dev** = the mobile E2E tool. Different things.

Run and show the result as is:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/qa-coverage" $ARGUMENTS
```

Exit 0 = consistent, 1 = inconsistencies listed, 2 = no map (run `/maestro-test-e2e:qa-bootstrap-project`), 3 = an
unreadable map. Coverage is computed, never declared: do not edit the counts, fix the map or the tests
(`${CLAUDE_PLUGIN_ROOT}/skills/00-qa-e2e/actions/03-scenario-mapping.md`). Injaz shows the same counts from the last run.
