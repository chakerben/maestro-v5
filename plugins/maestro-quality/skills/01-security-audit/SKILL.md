---
name: 01-security-audit
description: Deep on-demand security audit of the codebase or a scope — auth flows, injection surfaces, secrets handling, dependency risks, OWASP-aligned. Use for a periodic audit, before a release, or when touching sensitive surfaces. Real-time diff review is the official security-guidance plugin's job, not this one.
argument-hint: "[scope path]"
allowed-tools: Read, Grep, Glob, Bash
model: opus
effort: high
---

# Skill: security-audit

Adopt the AppSec engineer posture (maestro-dev references/expert-postures.md).

## Process

1. **Scope.** Whole repo or the given path. Map the sensitive surfaces first:
   auth (middleware, session, role checks), money (payment routes, webhooks),
   input boundaries (API routes, forms, file uploads), secrets usage.
2. **Authz pass.** For every route/server action: who can call it, is the
   check server-side, can an ID be swapped (IDOR)? Client-side-only checks
   are findings.
3. **Injection pass.** Raw SQL (`$queryRaw` with interpolation), `eval`/
   `Function`, `dangerouslySetInnerHTML`, unvalidated redirects, command
   concatenation.
4. **Secrets & config pass.** Hardcoded credentials (reuse
   maestro-vcs secret patterns), `.env` committed, secrets in client bundles
   (`NEXT_PUBLIC_` misuse), webhook signature verification present?
5. **Deps pass.** Run the ecosystem audit (`pnpm audit` etc.) and read the
   criticals — versions pinned? lockfile committed?
6. Report: findings by severity (critical/high/medium/low), each with file,
   evidence, exploit sketch (one line), and the concrete fix. Offer to open
   a task folder for the criticals.

## Test

- Every finding has a path + quoted evidence + a fix.
- No code was modified.
