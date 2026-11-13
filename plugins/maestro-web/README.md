# maestro-web

Web standards layered on the official frontend-design plugin.

## Skills

- `00-web-standards` — App Router server-first, Prisma migrations, one
  server identity module (provider behind it), session → permission →
  validation, 404 out of scope / 403 missing right, Zod at every boundary,
  env.ts pattern
- `01-ux-standards` — the 4 states, mobile-first, a11y floor, form ergonomics
- `02-design-review` — scored review: states/a11y/RTL/visual, from code,
  screenshot, or URL
- `03-motion` — CSS first, then GSAP + Lenis on marketing surfaces only,
  reduced-motion first, SplitText by words on Arabic, direction-aware offsets
- `04-db-safety` — no production URL on previews, guarded migrate in the
  production build only, idempotent ordered migrations, additive first,
  schema-vs-migrations diff around selective releases
- `05-api-boundaries` — opaque ids, PATCH without defaults, stable error
  codes, idempotent public writes, side effects after the response, files
  behind signed short-lived URLs
