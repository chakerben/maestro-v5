---
name: 01-security-audit
description: Deep on-demand security audit of the codebase or a scope — auth flows, injection surfaces, secrets handling, dependency risks, OWASP-aligned. Use for a periodic audit, before a release, or when touching sensitive surfaces. Real-time diff review is the official security-guidance plugin's job, not this one.
argument-hint: "[scope path]"
allowed-tools: Read, Grep, Glob, Bash
disallowed-tools: Write, Edit, NotebookEdit   # enforced: an audit never edits (allowed-tools alone only pre-approves)
context: fork   # the audit reads a lot and returns a report; the session keeps the report, not the reading
background: false   # fork defaults to background — the caller needs the report in this turn
model: opus
effort: high
---

# Skill: security-audit

Adopt the AppSec engineer posture — `maestro-dev`'s
`references/expert-postures.md` when that plugin is installed; else, in five
lines: assume every input is attacker-controlled, every tenant id is
forgeable, every secret leaks once in a bundle, every retry doubles a payment,
and a finding without the line that proves it is a hypothesis.

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
4. **Secrets & config pass.** Hardcoded credentials — when maestro-vcs is
   installed, run its `secret-scan.sh branch` and read the result; else grep
   for the generic shape `(api[_-]?key|secret|password|token)\w*\s*[:=]\s*['"]?[A-Za-z0-9+/=_.-]{16,}`
   and the common provider prefixes (`sk_live_`, `AKIA`, `ghp_`, `AIza`,
   `eyJ…`) — `.env` committed, secrets in client bundles
   (`NEXT_PUBLIC_` misuse), webhook signature verification present?
5. **Deps pass.** Run the ecosystem audit (`pnpm audit` etc.) and read the
   criticals — versions pinned? lockfile committed?
6. **Recurring findings pass.** Look for each line below; absence of the
   fix is a finding.
7. Report: findings by severity (critical/high/medium/low), each with file,
   evidence, exploit sketch (one line), and the concrete fix. Offer to open
   a task folder for the criticals.

## Recurring findings (step 6)

- Redirect target not validated on the parsed URL's origin, `//` or `/\`
  accepted — open redirect.
- CSV builder (server or client) not neutralising a leading `= + - @`, tab
  or CR — formula injection.
- User field unescaped in e-mail HTML or an href — HTML injection.
- Upload not validated at upload AND at serve, by magic bytes — stored
  content attack.
- Single-use token stored unhashed, not consumed by a conditional update,
  or surviving a re-issue — token replay.
- Account flow answering differently for known and unknown accounts,
  server failure included — enumeration.
- Sign-in not constant-time, refresh token without rotation and reuse
  detection, account linking on an unverified claim — account takeover.
- Token verification used as authorization; internal endpoint behind a
  platform key instead of a dedicated secret — privilege confusion.
- Client able to write an authorization or decision column — self-promotion.
- Row-security fix not tested as the application role (no superuser, no
  bypass attribute), definer objects unaudited — silent bypass.
- Boot accepting a known, published or placeholder secret — default secret
  in production.
- Starter-kit leftovers: public sign-up on, routes gated by "authenticated"
  only, preview cookie treated as authorization — unintended access.
- Privilege derived from a list in env (phones, e-mails) — backdoor.
- Agent-tool server on a private network without authentication — key
  exposure.
- A regex command guard presented as a security boundary — say in the
  report that it is not one.

## Test

- Every finding has a path + quoted evidence + a fix.
- The report states, for each recurring-findings line, found / not found /
  not applicable.
- No code was modified.
