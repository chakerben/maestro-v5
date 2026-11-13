---
name: 04-db-safety
description: Use when a task touches a database schema, a migration, a seed, a build or deploy command, or any script that writes to a database. Not for query performance (maestro-quality:02-perf-audit).
user-invocable: false
paths:
  - "prisma/**"
  - "**/migrations/**"
  - "vercel.json"
  - "scripts/**/*migrat*"
  - "**/seed*.{ts,js,mjs,sql}"
---

# Skill: db-safety

Every rule names the incident class behind it. Follow silently while
building; cite the rule when reviewing. **[guard]** = ship this as a test or
CI step, not as prose — when the project has no such guard, say so and
propose it; never build it unasked.

## Environments

- Preview and branch builds never receive a production database URL; scope
  DB variables per environment — because an unmerged branch migrated production.
- Migrations run in the production build only, behind a guard on the
  platform's environment variable; an absent variable means no-op; never on
  previews — because a shared build command ran on every preview.
- No destructive command (`db push --accept-data-loss`, `migrate reset`,
  seed, truncate) in any versioned build or deploy config — because a build
  emptied production. **[guard]** CI grep on the build command.
- Never pass a real database as shadow database or diff target — because
  the tool resets it.
- Local dev cannot push schema to a non-local database; print the resolved
  host class (local / preview / production) at boot — because a laptop sat
  on production unnoticed. **[guard]** boot log line.
- Ops scripts take the database URL as an explicit argument and print the
  target environment before any write — because an auto-loaded env file
  pointed at production.
- Production batch scripts: dry-run by default, `--apply` flag, backup
  first, throttled, applied list = announced list — because a broad delete
  removed live rows with recovery off.

## Migrations

- Every schema change ships its migration in the same commit; `db push`
  only on a local spike — because environments drift, then 500 on a missing
  column.
- Read each generated migration, cut it to the intended change, make it
  idempotent (`IF NOT EXISTS`, guarded backfills) — because generators add
  unrelated drops and renames.
- Folder names sort in dependency order (`YYYYMMDD_HHMM_slug`) and are
  unique — because two same-day migrations applied in the wrong order.
  **[guard]** test.
- Apply a new migration twice on a throw-away database, then diff schema
  against migrations: empty — because a non-idempotent or incomplete
  migration fails only in production. **[guard]** CI job on empty Postgres.
- Additive first: additive DDL reaches every database before the code that
  reads it; destructive DDL only after the code stopped reading — because
  deploy order caused minutes of 500.
- Selective release (cherry-pick, partial merge): diff schema against
  migrations on the release branch before AND after — because schema
  arrived without its migration.
- One tracked migrations folder, one runner, no hand-applied SQL — because
  hand-applied statements were forgotten and environments diverged.
- Before dropping or nulling a column, search functions, views, triggers
  and policies for it — because a definer function still read it.
- The ORM CLI uses the direct URL, the app the pooled one; the runtime role
  is not the migration owner — because poolers break advisory locks and an
  owner role bypasses row security.
- `postinstall` runs the client generator — because CI built on a stale client.

## Schema and queries

- Vocabularies that grow (statuses, types) are Zod-validated strings;
  database enums only for closed lists — because a new enum value needs DDL
  that one deploy path skipped, and every write using it failed.
- Uniqueness among live rows = partial unique index in a migration plus a
  re-check inside the write transaction — because a database built without
  migrations lacks the index.
- Compose tenant scope and user filters with `AND: [...]`, never by object
  spread — because a second `OR` replaced the tenant filter (cross-tenant
  leak). **[guard]** lint rule in tenant-scoped modules.
- Type standalone `select` / `include` objects (`satisfies`) — because an
  unknown key passes the type checker and 500s at runtime.
- One disposable test database per concurrent checkout; test config
  overrides every database name; migrate before testing — because a shared
  test database gave phantom failures and tests once wrote to a real one.

## Serverless

- Direct Postgres: pool ≤ 5, short idle timeout, bound to the platform
  lifecycle, `error` listener — because connection exhaustion took a site down.
- Functions run in the database's region, pinned in the versioned config —
  because cross-region calls cost seconds and the file overrides the dashboard.

## Test

A change made under this skill leaves: no destructive database verb in any
build or deploy config; the migrate step guarded to production builds only;
one migration per schema change, in the same commit, applied twice on a
throw-away database with an empty schema-vs-migrations diff (output shown,
not asserted); no script that writes without naming its target environment
first. A review under this skill cites the rule and names each missing guard.
