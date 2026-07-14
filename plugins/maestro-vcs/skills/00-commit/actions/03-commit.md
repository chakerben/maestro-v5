# 03 - Commit

Execute.

## Process

1. Precondition: action 01 reported green (or an explicit recorded bypass)
   AND action 02 produced an approved message. Otherwise refuse.
2. Commit. Never `--amend` on pushed commits, never `--no-verify`.
3. Report: hash, files, gate summary line.

## Test

- No commit exists without a green (or explicitly bypassed) gate in this session.
