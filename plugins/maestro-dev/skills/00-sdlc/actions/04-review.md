# 04 - Review

Independent verdict.

## Process

1. Spawn the `checker` agent with: spec.md, plan.md, the diff, and the expert
   posture. Fresh context — it must not see the build conversation.
2. Checker writes `review.md` (verdict, findings, score, evidence).
3. Verdict `ship` → mark plan `reviewed`, continue. Verdict `iterate` →
   loop to 03 with the findings as the work order (max 3 iterations,
   then `blocked`).
4. Findings the checker marks **out of scope** (pre-existing defects it met
   on the way) are never folded into the iteration: hand them to
   `maestro-pm:03-ticket` when installed, else list them in `review.md`
   under `## Out of scope` for the human.

## Test

- `review.md` exists with an explicit verdict and evidence-backed findings.
- The checker ran in a fresh context (no build history).
