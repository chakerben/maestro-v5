---
description: Triage one security finding of the Injaz QA security agent by hand — reproduce, then fix (the agent re-tests) or cancel with a reason it learns from. Never repeats a secret value.
argument-hint: "<ticket key, e.g. TECH-57>"
allowed-tools: Bash, Read, Glob, Grep
---

> **Maestro 5** = this plugin marketplace. **Maestro mobile.dev** = the mobile E2E tool. Different things.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/00-qa-security/actions/05-finding-triage.md` and follow it for `$ARGUMENTS`.
2. Ask the human for the ticket's details if they are not in the conversation (fingerprint, file, rule); never ask for
   the secret value itself.
3. State the verdict first — true positive, false positive, accepted risk — with the one fact that decides it.
4. True positive: propose the fix on a branch and the exact command that proves it. Do not change the ticket status
   yourself; tell the human which status to set and the reason to write.
