# maestro-payments

Money rules that hold whatever the gateway. No hook, no agent, no command.

## Skills

- `00-payment-integrity` — the server asks the gateway, amounts recomputed
  from the database in integer minor units, raw-body signed webhooks that
  are idempotent and backed by reconciliation, crash-safe refunds, explicit
  live-mode flag
