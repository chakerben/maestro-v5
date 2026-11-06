# 04 - Heal review

The agent's healer may change a TEST when the page changed (a label, a selector), never the application. Its diff is
evidence on an `improvement` ticket «الاختبار يحتاج تحديثاً»; it is **never pushed** (D22). A human decides here.

## What already happened before the ticket

- The failure was reproduced N/N times on the same project (fewer = flaky, action 05).
- The healer worked under a sandbox, with no shell and no web access; a diff outside the tests folder, or touching its
  own configuration, was discarded.
- The worker re-ran the healed test itself: the ticket exists only if it passed.
- The diff gate refused `test.fixme` / `test.skip` (that becomes a bug ticket) and flagged `.first()`, `nth(`,
  `waitForTimeout` as warnings in the ticket.

## Process

1. Open the ticket and its `…-heal.diff` artifact (Injaz › المشاريع التقنية › التذاكر).
2. Ask one question: **does the test still verify the same behaviour?** A label that changed from «إرسال» to «إرسال
   الطلب» — yes. An assertion removed, a value loosened, a wait added to hide a slow page — no.
3. Check the warnings: a `.first()` hides an ambiguous selector — ask for a test id instead.
4. Accept: apply the diff in a branch of the tested repository, run the test, commit
   (`test(e2e): follow the new label of the order button [ORD-002]`), set the ticket «مكتمل».
5. Reject: set the ticket «ملغي» with the reason in one line — Injaz records it as a learning and the agent stops
   proposing that change.
6. Mobile: the same for a Maestro mobile.dev flow repair (a renamed `testID`): verify the new id exists in the app source.

## Test

- An accepted heal is committed by a human in the tested repository with the scenario ref in the message; nothing was
  pushed by the agent.
- A rejected heal has a «ملغي» ticket with a reason.
- A diff that removes an assertion or adds `waitForTimeout` is never accepted as is.
