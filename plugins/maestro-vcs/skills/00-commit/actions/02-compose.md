# 02 - Compose

Write the conventional commit message.

## Process

1. Type from the diff nature: feat | fix | refactor | test | docs | chore |
   perf | ci. Scope from the dominant module or the task slug.
2. Subject: imperative, <= 72 chars, no trailing period, plain English
   (project convention may override to FR).
3. Body when the diff is non-trivial: WHY over what, 3 bullets max. Reference
   the task folder (`maestro_docs/tasks/<...>`) when one exists.
4. If the gate was bypassed: append `Gate-Bypass: <reason>` to the body.
5. Show the message for approval (interactive) or proceed (auto mode callers).

## Test

- The subject line parses under commitlint conventional rules.
- A bypassed gate is visible in the commit body.
