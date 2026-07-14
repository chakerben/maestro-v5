# 03 - Maestro plugins

Enable the Maestro plugins relevant to the stack profile.

## Input

The stack profile from `01-detect-stack`.

## Output

The relevant Maestro plugins installed at project scope, status reported.

## Recommendation matrix

| Signal | Maestro plugin |
|---|---|
| Always | `maestro-core` (this plugin — verify present) |
| Always | `maestro-dev`, `maestro-quality`, `maestro-vcs` |
| Next.js / web frontend | `maestro-web` |
| React Native / Expo / Flutter | `maestro-mobile` |
| Product docs wanted (ask) | `maestro-pm` |

## Process

1. Build the list from the matrix, check what is already enabled, present the
   remainder, wait for approval.
2. Install: `claude plugin install <name>@maestro --scope project`
3. Report per-plugin status.

## Test

- Every approved plugin appears in `claude plugin list`.
- Nothing was installed without approval.
