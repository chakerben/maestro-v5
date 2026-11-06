---
description: Review one heal diff the QA agent attached to an improvement ticket — accept it into a branch, or reject it with a reason so the agent learns.
argument-hint: "<ticket key, e.g. TECH-42> | <path to a .diff>"
allowed-tools: Bash, Read, Edit, Glob, Grep
---

> **Maestro 5** = this plugin marketplace. **Maestro mobile.dev** = the mobile E2E tool. Different things.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/00-qa-e2e/actions/04-heal-review.md` and follow it for `$ARGUMENTS`.
2. A ticket key: ask the human for the `…-heal.diff` artifact (Injaz shows it on the ticket); a path: read it.
3. State the verdict first — same behaviour verified, or not — with the line of the diff that decides it.
4. Accept only on the human's word: apply the diff in a feature branch of the tested repository, run the test, commit
   with the scenario ref. Never push to the default branch.
