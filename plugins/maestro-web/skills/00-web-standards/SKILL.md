---
name: 00-web-standards
description: The Maestro web stack conventions — Next.js App Router, Prisma/PostgreSQL, Clerk, Zod, Tailwind. Auto-applies when building or reviewing web code. Deviations require a recorded decision. Not for mobile (maestro-mobile) or generic UI polish (official frontend-design plugin).
user-invocable: false
---

# Skill: web-standards

The opinionated stack, enforced with reasons. Follow silently while building;
cite the rule when reviewing; record any justified deviation in
tech-decisions.md.

## Stack

- **Next.js App Router** — server components by default; `"use client"` is
  the exception and sits at the leaf, never on a page for one hook.
- **PostgreSQL + Prisma** — schema is the source of truth; every schema
  change = a migration (never `db push` beyond local spikes).
- **Clerk** auth — authorization checked SERVER-SIDE on every route/server
  action; middleware protects segments, but each mutation re-verifies.
- **Zod at every boundary**: API input, server action args, env
  (`env.ts` pattern — no raw `process.env` reads outside it), external API
  responses, webhooks (after signature verification).
- **Tailwind** with logical utilities (`ms-*`/`me-*`) when the project has
  or may have an `ar` locale.

## Non-negotiables

- No hardcoded URLs, keys, or secrets — env vars only; `NEXT_PUBLIC_` only
  for truly public values.
- Server actions: validate input (Zod) → authorize (Clerk) → act → revalidate.
  In that order, every time.
- Errors: no empty catch; user-facing errors are localized messages, logs
  carry the cause; error.tsx boundaries per segment.
- Data fetching: no waterfalls — parallelize with Promise.all; paginate every
  unbounded list; `select` what you render.
- Forms: server-validated even when client-validated; optimistic UI only
  with rollback.
- Every user-facing string through the i18n layer if the project is
  multilingual (delegates depth to maestro-mobile:01-rtl-i18n — it covers web too).
