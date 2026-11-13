---
name: 05-api-boundaries
description: Use when writing or reviewing an API route, a server action, a validation schema, an error response or a public form. Not for authorization (00-web-standards) or payments.
user-invocable: false
paths:
  - "**/route.{ts,js}"
  - "**/validations/**"
  - "**/schemas/**"
---

# Skill: api-boundaries

What crosses the wire, in and out. Every rule names the incident class
behind it. **[guard]** = ship this as a lint rule or a test, not as prose —
when the project has none, say so and propose it; never build it unasked.

## Input

- Ids are bounded opaque strings checked for existence, never for format —
  because rows seeded elsewhere had another id shape and every write
  failed. **[guard]** lint ban on `.cuid()` / `.uuid()` for id fields.
- Optional fields accept `null` and `undefined` through one shared helper —
  because clients send either and one of them 400s.
- Strict schemas on write, tolerant on read (ignore unknown members,
  survive legacy rows) — because one legacy row 500'd a whole list.
- Never build a PATCH schema with `.partial()` over fields carrying
  `.default()`; PATCH sends changed fields only — because defaults wiped
  stored values. **[guard]** lint rule.
- One version of the validation library across app, API, tests and
  container — because rules were green in tests and violated when deployed.
  **[guard]** duplicate-major dependency check.
- One schema per form step, shared by client and server — because two
  schemas for one step blocked submission with no message.

## Writes

- A public write is a route handler with origin/CSRF check, schema,
  honeypot, durable rate limit and idempotency key; no public server
  action — because public actions were spammed and double-submitted.
- Every user-triggered create accepts an idempotency key — because double
  taps and lost responses are normal.
- Race-prone decisions use a conditional update (`where id AND status =
  expected`, zero rows → 409) or a serializable transaction with retry →
  409 — because two actors both passed a read-then-write check.
- Derived values (remaining, paid, status, totals) are computed, never
  stored — because ledger and summary drifted.
- Snapshot what a record used at the time (names, stages) — because a later
  template edit rewrote history.
- Business-time rules (cutoff, "today", period) run server-side in the
  business time zone with an injected clock — because server UTC and device
  clocks disagree around midnight.
- Side effects (mail, notification, analytics) run after the response,
  never throw into the request, and count their failures — because a mail
  outage failed the business write.
- Long work = job row + background run + watchdog + re-downloadable
  result — because it exceeded the function ceiling.

## Output

- The server returns a stable error code plus a safe message; clients
  switch on the code, never on message text — because substring matching
  showed the wrong error and raw validator output reached the screen.
- A refused form names the field, keeps the user's input and logs the
  reason — because a bare "invalid" made tickets nobody could diagnose.
- A fallback sender reports which provider really delivered, and the status
  screen reads that before saying "sent" — because a console fallback
  claimed success.
- Never return a storage URL or key: return availability flags and serve
  files through a route that checks ownership and signs a short-lived URL —
  because a raw URL outlives the permission.
- Assert the exact key set of a payload crossing a tenant or trust
  boundary — because an absence test cannot see the key added tomorrow.
  **[guard]** exact-key-set test.
- Tie the written contract (OpenAPI or shared package) to the routes by a
  test in both directions — because clients and server drifted silently.
  **[guard]** contract-vs-routes test.

## Test

Code written under this skill: no id schema validates a format; no PATCH
schema is a `.partial()` of one with `.default()`; every error response
carries a stable code and no raw validator output; every public write is a
route handler with a rate limit and an idempotency key; no payload returns
a storage URL or key; no mail or notification call can fail the write that
triggered it. A review under this skill cites the rule and names each
missing guard.
