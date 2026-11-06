# 05 - Flaky policy

Flaky = fails, then passes, on the same commit. It is never a bug ticket (D20).

## Rules (plan §6.5 rule 11)

| Situation | What happens |
|---|---|
| A failure reproduces N/N on replay | real failure → bug ticket (or a heal, action 04) |
| Fewer than N/N | `flaky` → a low-severity ticket «اختبار متذبذب» with the counts, never a bug |
| 3 instabilities in 14 days, or > 5 % of runs | quarantine: tag `@quarantine` + an annotation pointing at the ticket; out of the gate |
| 20 consecutive passes in quarantine | back in the gate, tag removed |
| 100 % failure for 7 days | `broken` — a real bug, never a quarantine |
| No instability for 30 days | the quarantine ticket closes itself |
| Observation month (`observeOnly`) | no quarantine at all — findings are «مقترح» only |

The replay budget is bounded per night: when it is spent, a failure is reported as reproduced once.

## Process

1. From the ticket, read the counts (`failures / attempts`) and the projects it failed on.
2. Look for the usual causes before touching the test: a shared account used by two tests, time and time zone
   (Riyadh vs UTC), animation, a third-party request not cut, an order dependency between tests.
3. Fix the cause in the test (isolation, a web-first assertion). Never add a fixed wait, never `retries` in the spec.
4. Quarantine only by the rule above, with the ticket in the annotation:
   `test('… [REF] @quarantine', { annotation: { type: 'issue', description: 'TECH-42' } }, …)`.

## Test

- A quarantined test carries both the tag and the ticket annotation; no test is quarantined during observation.
- A fix never adds `waitForTimeout`, `retries` or `test.skip`.
