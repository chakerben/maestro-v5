# 03 - Passive checks

What the agent observes on a running environment without attacking it.

## Headers and TLS (`headers`)

- One GET per URL declared on the environment (the base URL plus `inspectUrls`, same host only), one second apart. The
  only security lane allowed on **production** (A38), and only when the environment allows header inspection.
- Checks: HTTPS redirect from http, HSTS, a CSP, frame protection (`frame-ancestors` / `X-Frame-Options`),
  `X-Content-Type-Options`, `Referrer-Policy`, cookie flags (`Secure`, `HttpOnly`, `SameSite`), TLS version, certificate
  validity and expiry.
- **D18**: a 401 / 407, an anti-bot challenge (403 / 429 / 503 with a challenge page), an invalid certificate on the
  first request, a 5xx or no answer = the ENVIRONMENT. The run ends `blocked_env` with the raw code; no finding.
  A Vercel deployment protection is not a security bug.

## ZAP passive (`dast_passive`)

- OWASP ZAP baseline in passive mode only, in a container pinned by digest, against the **local** environment (the app
  started from `qa/local-server.json`). Never staging, never production, never active rules.

## Process

1. Reproduce a header finding with one request: `curl -sSI https://<declared host>/` — on a declared environment only.
2. Fix it where headers are owned (Next.js `next.config.ts` `headers()`, or `vercel.json`, which overrides it — check
   both), deploy to staging, let the re-test confirm.
3. `blocked_env` on a protected preview: there is no protection bypass, by design. Declare an environment the agent
   can reach (an unprotected staging, or `local`), or accept that this one is not scanned; never ask the agent to get
   around a protection.

## Test

- A header fix is visible in `curl -sSI` on staging before the ticket moves to «اختبار».
- No request in this action targets a host that is not a declared environment of the project.
