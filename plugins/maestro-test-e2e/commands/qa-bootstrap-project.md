---
description: Tie this repository to its Injaz technical project and add the missing qa/ skeleton. Refuses — writing nothing — when Injaz ties the repository to no project or to several. Never overwrites a file, never writes a secret.
argument-hint: "[--dry-run]"
allowed-tools: Bash, Read, Write, Glob, Grep
---

> **Maestro 5** = this plugin marketplace. **Maestro mobile.dev** = the mobile E2E tool. Different things.

Prepare this repository for the Injaz QA agents. `$ARGUMENTS` may contain `--dry-run` (plan only, write nothing).

1. Resolve the project — the script reads the workstation key itself; never open `~/.config/injaz-qa/.env`, never
   print or pass a key:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/bin/qa-resolve-repo" --json
   ```

2. Exit code other than 0 → **stop, write nothing**, and say what to do:

   | Exit | Meaning | Tell the user |
   |---|---|---|
   | 3 | no Injaz project claims this repository | set the repository in the project's edit form (Injaz › المشاريع التقنية) or declare a QA target on it, then rerun |
   | 4 | several projects claim it | the codes listed; fix the repository links in Injaz first |
   | 5 | no GitHub `origin` | nothing to resolve |
   | 6 | no workstation key | create «محطة مطوّر (قراءة فقط)» in Injaz › الإعدادات › وكلاء الجودة › الأجهزة, store it with `qa-set-workstation-key` (it asks, hidden; never paste a key in the chat) |
   | 7 | Injaz refused or unreachable | the code it gave (`WRONG_ENV`: the key belongs to the other Injaz) |

3. Exit 0 → the JSON names one project (`projects[0].code`) and its QA targets. Create only what is MISSING:
   - `qa/map/<CODE>.scenarios.json` → `{ "project": "<CODE>", "version": 1, "entries": [] }`;
   - `qa/README.md` → five lines: what `qa/` holds, the map file, `/maestro-test-e2e:qa-map-scenarios`,
     `/maestro-test-e2e:qa-coverage`, and that no secret ever goes in this folder.
   An existing file is left exactly as it is and reported as kept.
4. Report, without changing anything else:
   - `@playwright/test` in `package.json` (expected exactly `1.64.1`) for a web target;
   - the test folder found (`qa/e2e`, `e2e`, `tests/e2e`, `tests`) or none;
   - `.maestro/` top-level flows for a mobile target; `qa/safari/` for Safari on iOS;
   - `injaz-test-scenarios.json` at the root — absent: next step `/injaz-test-scenarios <CODE>`, present: next step
     `/maestro-test-e2e:qa-map-scenarios`.
5. Check what you wrote: `grep -rnE "qa_[A-Za-z0-9]{8}|sk-or-|password" qa/` must print nothing.
6. Do not commit; list the created and kept files and the next step.
