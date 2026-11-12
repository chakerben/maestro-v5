---
name: 04-secrets-and-env
description: Use when reading, setting, rotating or debugging an environment variable or a secret, or when a command or page could display one. Not for the commit-time secret scan (maestro-vcs:00-commit).
user-invocable: false
---

# Skill: secrets-and-env

A secret shown once in a transcript is leaked. Every rule names the incident
class behind it. **[guard]** = ship this as a boot check, a test or an
onboarding step, not as prose — when the project has none, say so and
propose it; never build it unasked.

## Never display

- Never print an env line, and never open a page or run a command whose
  output shows a secret, even "masked" — because secrets reached
  transcripts three times in a month. Ask for the name, the length or a
  hash; test presence with `[ -n "$VAR" ]`.
- Child processes of an agent get an env rebuilt from an allow-list —
  because an inherited env exposes every key.

## Setting and moving

- After setting a secret, validate its shape and make one real call with
  it — because a clipboard paste stored the wrong value.
- A value pulled from a platform CLI may be a placeholder; never copy
  secrets between environments by pull — because a placeholder string was
  deployed as a key.
- Before any write, check which environment each tool points to (CLI,
  connector and dashboard may differ) — because a connector was scoped to
  production.
- Explicit beats implicit: pass the target URL or variable on the command
  line — because a runner auto-loaded a local env file aimed at production.

## At boot and in the repository

- A missing required secret fails the boot, and a placeholder is rejected —
  because a service ran for weeks on a dummy value. **[guard]** boot
  validator.
- Deploy and build ignore files exclude env files — because the CLI
  uploaded them.
- A config file is never allowed to hold the key — because config files get
  committed and copied.
- Scan the full history before a repository gets its first remote —
  because a fork carried its parent's leaked files. **[guard]** onboarding
  step.

## Test

- No command run under this skill wrote a secret value to the transcript:
  no `cat` of an env file, no bare `env` / `printenv`, no platform
  "env ls / pull" to stdout.
- A secret set under this skill was followed by one real call that used it,
  and its result is shown.
- Every write command names its target environment explicitly.
