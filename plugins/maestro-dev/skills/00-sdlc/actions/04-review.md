# 04 - Review

Independent verdict.

## Process

1. Spawn the `checker` agent with: spec.md, plan.md, the diff, and the expert
   posture. Fresh context — it must not see the build conversation.
   If the project has an `ar` locale (`messages/ar*`, `**/ar.json`, `*.arb`),
   also spawn `m-i18n-checker` in parallel, on the same diff.
2. The checker RETURNS a structured verdict (verdict, findings, score,
   evidence) — it has no write tool. The orchestrator writes it to
   `review.md` in the feature folder, merging the i18n findings when that
   agent ran.
3. Verdict `ship` → mark plan `reviewed`, continue. Verdict `iterate` →
   increment `iterations` in plan.md; at 3 set `status: blocked` and stop.
   Else write the in-scope findings as `phase-N+1.md` (`status: pending`,
   scope = the findings, criteria = the failed ones) and re-enter 03.
4. Findings the checker marks **out of scope** (pre-existing defects it met
   on the way) are never folded into the iteration: hand them to
   `maestro-pm:03-ticket` when installed, else list them in `review.md`
   under `## Out of scope` for the human.

## Test

- `review.md` exists, written by the orchestrator from the returned verdict,
  with evidence-backed findings (and the i18n verdict when `ar` exists).
- The checker ran in a fresh context (no build history).
- On `iterate`, plan.md `iterations` grew by 1 and a new pending phase file
  carries the findings; at 3 the plan reads `status: blocked`.
