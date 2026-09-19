# maestro-quality

Workflow-time quality. No runtime enforcement.

## Hooks

Exactly one (Philosophy rule #1): `PreToolUse(Bash)` → `bash-guard.js` —
accident guard, ~30–60 ms (Node start-up; the regex work itself is < 1 ms),
fail-open. Code-diff review is the official
security-guidance plugin's job (rule #8).

## Skills

- `00-quality-gate` — own gates.json (off/standard/high/paranoid), on-demand runs
- `01-security-audit` — deep OWASP-aligned audit with AppSec posture
- `02-perf-audit` — measure-first performance audit (DB/server/client/mobile)
