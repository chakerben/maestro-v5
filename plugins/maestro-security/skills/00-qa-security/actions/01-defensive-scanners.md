# 01 - Defensive scanners

The repository lanes: `secrets`, `deps`, `sast`. Versions are pinned and their exact invocations are printed by the
worker's doctor on the QA machine (`uv run python -m worker doctor`).

## What each lane decides

| Lane | Finding | Severity |
|---|---|---|
| `secrets` (gitleaks) | a credential pattern in the tree or the history | named credential (AWS, GitHub, Stripe…) **critical**; generic rule **high**, **medium** in test / fixture paths |
| `deps` (OSV-Scanner + Trivy) | an INSTALLED version inside a vulnerable range | the advisory's; a ticket only at **high** and above, with the first fixed version and the exact upgrade command |
| `sast` (Semgrep / Opengrep) | a rule match in application code | the rule's; code outside the app (design files, scripts, tests) counts **low** |

- Rules are fetched at run time (`--config p/<name>`: `p/typescript`, `p/react`, `p/nextjs`, `p/expressjs` — not
  `p/express`, `p/secrets`); no rule file is ever copied into a repository (A40).
- **Opengrep, not Semgrep**, for code ContentCo does not own (the EJART tenant, IJARP, client sites). Until Opengrep and
  its rules are installed on the QA machine, such a run ends `blocked_env OPENGREP_RULES_MISSING` — never a fallback.
- gitleaks is in maintenance; `betterleaks` is followed as its successor by the watch (no switch yet).
- Each lane has a severity floor (high, except headers / ZAP: medium): below it a finding goes to the weekly digest.

## Process

1. Read the finding's fingerprint: its prefix names the lane, the rest the rule / package and the file.
2. `deps`: check the installed version in the lockfile, the fixed version in the advisory, run the command the ticket
   gives on a branch, run the project's tests.
3. `secrets`: find whether the value is real (a live key) or a placeholder. Real → rotate in the provider's console,
   then remove it; placeholder in a test → say so and cancel with that reason.
4. `sast`: read the code path from the entry point to the sink; a match on code that never ships is a false positive.

## Test

- A `deps` fix moves the installed version out of the advisory's range (the lockfile proves it).
- A `secrets` true positive is rotated before the ticket is closed; its value appears nowhere in the work.
