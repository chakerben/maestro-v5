---
name: 00-payment-integrity
description: Use when code creates, confirms, refunds or reconciles a payment, handles a gateway webhook, or computes an amount to charge (paiement, checkout, webhook, refund). Not for pricing UI.
user-invocable: false
---

# Skill: payment-integrity

Gateway-independent. Every rule names the incident class behind it. Follow
silently while building; cite the rule when reviewing. **[guard]** = ship
this as a test or a boot check, not as prose — when the project has none,
say so and propose it; never build it unasked.

## Truth

- The server decides payment success by asking the gateway; SDK results and
  redirect parameters are hints — because clients reported success for
  unpaid orders.
- The server recomputes every amount from the database; the client sends
  ids and quantities only — because stale carts under-charged and raised
  false tamper errors.
- Money is integer minor units end to end; totals are recomputed, never
  incremented or decremented — because floats and running totals drift.
  **[guard]** CI grep for float arithmetic on amount fields.
- Money invariants (overpayment, remaining, caps) are checked inside a
  serializable transaction or a conditional update — because two concurrent
  payments both passed the check.

## Webhooks

- Read the raw body before any JSON parser, verify the signature, give the
  route its own rate limiter — because a parsed body fails the signature
  check and a shared limiter dropped gateway retries. **[guard]** test that
  the route is mounted before the parser.
- Never answer 2xx to an event that was not processed — because the gateway
  stops retrying and the payment is lost.
- Handlers are idempotent and order-independent; verify the list of
  subscribed event types — because events arrive twice, out of order, or
  never. **[guard]** test posting one event twice and two in reverse order.
- Every side effect of "paid" lives in one idempotent state-transition
  function, called by the webhook AND the synchronous confirm — because
  whichever path won, the other's effects were missing.
- Every webhook is backed by a periodic reconciliation job (wall-clock
  budget, random sampling of old rows) — because gateway retry policy is
  undocumented; the webhook is only an accelerator.

## Failures and refunds

- Classify gateway failures as transient / misconfigured / absent; an auth
  error from the gateway is never a terminal "payment failed" — because a
  rotated key marked real payments as failed.
- Refund = committed intention marker → gateway call outside the
  transaction → bookkeeping; "already refunded" is success — because a
  crash between steps double-refunded or lost the refund.
- No business data in gateway metadata: store it, pass a reference —
  because metadata size and key caps caused a payment outage.

## Configuration

- Sensitive behaviour hangs on an explicit live-mode flag, never on
  `NODE_ENV`; boot refuses test credentials in live mode and unsafe flag
  combinations — because acceptance environments also run in production
  mode. **[guard]** boot test on the flag combinations.
- Keep a read-only smoke script that proves the live credentials and the
  webhook endpoint — because misconfiguration was found by customers.
- The provider sits behind an interface with a stub selected by env —
  because the product must be testable before the contract is signed.
- Remove dead payment integrations from the tree — because they mislead
  every reader and auditor.

## Test

Code written under this skill: no order, booking or balance turns "paid" on
a client-reported result; no amount to charge is read from the request
body; no float arithmetic on an amount; the webhook route verifies the
signature on the raw body and answers non-2xx when processing failed;
posting the same event twice changes state once; the webhook and the
synchronous confirm call the same transition function. A review under this
skill cites the rule and names each missing guard.
