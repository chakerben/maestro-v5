---
name: 04-deploy-verify
description: Use right after a merge or push that triggers a deployment, before telling anyone a change is live, when preparing a selective (cherry-pick) release, and when a user reports "nothing changed" after a release. Not for tagging (02-release).
---

# Skill: deploy-verify

"Merged" is a git fact; "live" is a fact about a running system. This skill
turns the second into evidence. Every rule names the incident class.

## Before the release

- Order: database → server → clients and workers; the server's strict
  validator must already accept a field before a client sends it — because
  a client shipped a field the server refused.
- **Migrations run as a guarded step of the production build only, never
  on a preview or branch build** — because a preview migrated the shared
  database from an unreleased branch.
- Additive first (add, backfill, switch, drop in a later release), and **no
  destructive database command in any build configuration** (no schema
  push that accepts data loss, no reset) — because a build emptied tables.
  Schema rules in depth: `maestro-web:04-db-safety` when installed.
- **Selective (cherry-pick) releases are allowed** — only approved work
  reaches production — and each one carries a **schema-versus-migrations
  diff before and after**: the release branch's schema must be exactly what
  its migration folder produces, and after the deploy the production
  database must match it — because a cherry-picked schema change without
  its migration answered 500 in production. Not empty = stop, no release.
- Deploy settings that change security (auth verification flags, regions)
  live in versioned config, not in a CLI flag or a comment — because one
  deploy silently opened an endpoint.

## After the deploy

- Wait for the real deployment to reach Ready and identify it **by commit
  sha** — because a cancelled duplicate reported success.
- Smoke-call one real endpoint the change touches — because a runtime-only
  error passed every static check.
- Assert one invariant (route list, sitemap URL count, health probe) —
  because a build-time failure produced an empty artefact.
- Do the final visual check on the production build — because dev mode
  hides font and cache differences.
- Append one line to the deploy log: what, sha, when, how it was verified
  — because nobody could say what was live.

## When someone reports a problem

- "Nothing changed": ask for a hard reload and compare the deployed version
  with the expected sha first; redeploy last — because the cause was a
  stale tab, more than once.
- Read the production logs for the reported time before forming a theory —
  because the generic error hid a specific one.
- Compare deployed content with the repository before redeploying a
  function — because out-of-band deploys had drifted.
- An API that does not deploy on merge is a defect to fix, not a step to
  remember — because server fixes sat merged and not live.

## Ship as guards, not as prose

- A wait-for-deploy script keyed on the commit sha (exit 0 only on Ready).
- The schema-versus-migrations diff as a release-script step and a CI job.
- A post-deploy smoke script; a drift check of deployed functions.

## Test

- Every "it is live" statement made under this skill quotes: the deployed
  sha, the Ready state, the smoke call with its status code, and the
  deploy-log line.
- A selective release leaves two diff outputs (before, after), both empty.
- No build configuration of the project contains a database command on
  preview builds, nor a destructive one anywhere.
- On a "nothing changed" report, no redeploy happened before the version
  check.
