# 05 - Finding triage

A human decides one security finding or ticket in Claude Code — usually a **critical** one, or one the open-weights
triage marked «يحتاج مراجعة بشرية».

## What the agent already did

- Only code findings and generic secret matches went to a model (GLM → DeepSeek → the floor model, the next one only on a
  provider error), with masked code; a false positive at ≥ 0.8 confidence was dropped and counted, anything else was
  filed with the model's one-line reading in the details.
- Facts (dependency in range, missing header, named credential) were filed without a model.
- A model refusal ended the run `blocked_by_policy` with an `improvement` ticket.

## Process

1. Read the ticket: fingerprint, file, rule, the model's reading if any. Do not paste the finding's masked line into
   another tool.
2. Reproduce on your machine when the tool is installed, on the same commit (e.g. `gitleaks detect --no-git -s <path>`,
   `osv-scanner --lockfile=bun.lock`, `semgrep --config p/typescript <file>`); otherwise follow the code path by reading.
3. Decide, then say why in one line:
   - **true positive** → fix on a branch (actions 01–03 per lane), the ticket goes «اختبار» and the agent re-tests it;
   - **false positive** → «ملغي» with the reason: Injaz records it as a learning and mutes the fingerprint;
   - **accepted risk** → «ملغي» with «مخاطرة مقبولة» and who accepted it.
4. A real secret: rotate first, then fix, then close. Never in the reverse order.

## Test

- The ticket ends «مكتمل» (after the re-test) or «ملغي» with a reason; no finding is closed without one.
- The reason never contains the secret value.
