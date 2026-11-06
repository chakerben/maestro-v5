# 04 - Scope and licences

## Scope

- `docs/qa-agent-scope.md` (Injaz repository) lists, per project: targets, declared environments, test accounts **by
  variable name**, what is forbidden, and the owner's written validation. It is the reference of `QaEnvironment`:
  nothing is tested that is not in it, and **nothing starts before it is signed** (H16).
- Never a target: a client's, a supplier's or a public platform's asset — not even read-only, automated.
- Production: the `@readonly` smoke (a reduced-rights account), header / TLS inspection, dependencies computed from the
  repository. Never a write, never `request-otp`, never `change-password`, never an account creation on a real
  environment. Writes on production are refused in the database before a run is claimed (D17).

## Licences (A40)

| Tool | Licence | How it is used |
|---|---|---|
| Semgrep CE | engine LGPL-2.1, rules «Semgrep Rules License v1.0» | rules fetched at run time (`--config p/<name>`), never vendored; reports internal; internal use on our own code only |
| Opengrep | LGPL-2.1 | default for code ContentCo does not own (EJART tenant, IJARP, client sites) |
| MobSF | GPL-3.0 | separate container, no code linking |
| OWASP ZAP | Apache-2.0 | separate container |
| gitleaks | MIT, maintenance only | `betterleaks` followed as successor |
| the pentest tool of the first plan | AGPL-3.0 | **not integrated** |

## Process

1. A request to scan something new: check it is in `docs/qa-agent-scope.md` for that project; if not, it needs the
   owner's signature first — say so and stop.
2. A request to add a tool: check its licence against the table's pattern (separate service for copyleft, nothing
   vendored) before anything else.

## Test

- No answer authorises a target or environment absent from the signed scope file.
- No change copies a Semgrep rule file into a repository.
