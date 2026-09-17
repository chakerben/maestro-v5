# 02 - Compose

## Convention check — first, always

Read `CLAUDE.md`, `.claude/rules/*.md`, and `git log --oneline -20`. A
project that states its own format gets its own format (and its own
version-bump rule, and its own language). Announce the detected convention
in one line before proposing the message. Only when nothing is stated do
you use Maestro's default (conventional commits).

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
