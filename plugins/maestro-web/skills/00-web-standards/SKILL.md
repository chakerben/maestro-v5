---
name: 00-web-standards
description: The Maestro web stack conventions — Next.js App Router, Prisma/PostgreSQL, one server identity module, Zod, Tailwind. Auto-applies when building or reviewing web code. Not for mobile (maestro-mobile) or UI polish (frontend-design plugin).
user-invocable: false
paths:
  - "app/**/{page,layout,route,loading,error,not-found,template,default}.{ts,tsx}"
  - "src/app/**/{page,layout,route,loading,error,not-found,template,default}.{ts,tsx}"
  - "prisma/**"
  - "proxy.ts"
  - "src/proxy.ts"
  - "middleware.ts"
  - "src/middleware.ts"
  - "next.config.*"
---

# Skill: web-standards

The opinionated stack, enforced with reasons. Follow silently while building;
cite the rule when reviewing; record any justified deviation in
tech-decisions.md.

## Stack

- **Next.js App Router only** (no Pages Router) — server components by
  default; `"use client"` is the exception and sits at the leaf, never on a
  page for one hook.
- **PostgreSQL + Prisma** — schema is the source of truth; every schema
  change = a migration (never `db push` beyond local spikes).
- **Auth: one server identity module**, the provider behind it (Clerk,
  Auth.js, own tokens — the project's recorded choice); no other file
  imports the provider — because a provider change stays an inside-only
  edit and checks stop diverging.
- **Zod at every boundary**: API input, server action args, env
  (`env.ts` pattern — no raw `process.env` reads outside it, `next.config.*`
  and `instrumentation.ts`), external API responses, webhooks (after
  signature verification).
- **Tailwind** with logical utilities (`ms-*`/`me-*`) when the project has
  or may have an `ar` locale.

## Non-negotiables

- No hardcoded URLs, keys, or secrets — env vars only; `NEXT_PUBLIC_` only
  for truly public values.
- Every route handler and server action: session → permission → validate
  (Zod) → act → revalidate, in that order — because validating first
  answers callers who have no right to the route.
- Public writes and writes called by a mobile app are API route handlers;
  server actions only for authenticated back-office writes — because
  public actions were spammed and a native client cannot call one.
- Errors: no empty catch; the server returns a stable code plus a safe
  message already localized (Arabic when the project has `ar`), the client
  switches on the code, logs carry the cause; error.tsx per segment —
  because matching on message text showed the wrong error.
- Data fetching: no waterfalls — parallelize with Promise.all; paginate every
  unbounded list; `select` what you render.
- Forms: server-validated even when client-validated; optimistic UI only
  with rollback.
- Every user-facing string through the i18n layer if the project is
  multilingual (depth in maestro-mobile:01-rtl-i18n when installed — it covers web too).

## Authorization and identity

**[guard]** = ship this as a test, not as prose; when the project has none,
say so and propose it.

- Authorize inside every server function, route handler and page data
  function; layout, `proxy.ts` (Next 16; `middleware.ts` on Next ≤ 15) only
  redirect — because a page streamed data before the layout redirected and
  a forged cookie passes the proxy. **[guard]** a test walks every route and
  action file for the guard call; public routes sit on an allow-list, each
  with its reason.
- The token proves identity; the database decides authorization, re-read on
  each access — because revoked accounts kept access until token expiry.
- Permissions are data (module + action), never `role === 'admin'` in code
  — because each hard-coded role refused a holder of the right.
- An object out of the caller's scope answers the same 404 as a missing
  one; a feature without permission answers 403 and a screen naming the
  missing right — because a 403 on an object confirms it exists, and a bare
  error on a feature gets retried forever.
- Provider outage (5xx, 429, network) → 503; only token errors → 401 —
  because an outage signed every user out.
- Client permission guards mirror the server guard and deny while loading —
  because fail-open guards flashed forbidden screens. **[guard]** one test
  reads both.
- No delete cascade across authorities: 409 while children guarded by
  another permission are live — because one delete right wiped rows
  another right protected.
- One token type (secret, salt, issuer) per audience — because a token of
  one app must never open another.

## Test

Code written under this skill: every server action and route handler shows
the order session → permission → validate (Zod) → act → revalidate; the
auth provider is imported by the identity module only; no public or
mobile-called write is a server action; error responses carry a stable
code; an out-of-scope id answers 404; no `process.env` read outside
`env.ts`, `next.config.*` and `instrumentation.ts`; no empty `catch`. A justified deviation from the stack
exists only with a matching line in `maestro_docs/memory/tech-decisions.md`.
