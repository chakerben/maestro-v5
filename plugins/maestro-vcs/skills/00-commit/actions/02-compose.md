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
4. Trailers, one per line, each ≤ 100 chars (commitlint caps footer lines;
   wrap a long reason onto a second `Gate-Allow:` line): every `ALLOWED`
   entry of the gate's secrets scan as `Gate-Allow: <file>:<line> <reason>`;
   a bypassed gate as `Gate-Bypass: <reason>`.
5. Show the message for approval; proceed without a pause when the caller
   said `auto` (`00-sdlc`, `02-implement` pass it) — the gate still ran.

## Test

- The subject line parses under commitlint conventional rules.
- A bypassed gate, and every `gate:allow` line of the diff, is visible in the
  commit body as a trailer; no trailer line exceeds 100 chars.
