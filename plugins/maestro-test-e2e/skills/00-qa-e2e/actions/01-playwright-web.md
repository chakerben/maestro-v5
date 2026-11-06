# 01 - Playwright web

Write or fix a Playwright test that the QA agent's web lane (`e2e_web`) can run unattended.

## What the lane does with the repository

- Pins `@playwright/test@1.64.1` from the project's own `package.json` (`npx --no-install playwright`): add it as a
  devDependency at that exact version, never `@latest`.
- Looks for the tests in `qa/e2e`, `e2e`, `tests/e2e`, then `tests` — the first folder that exists.
- Runs them with ITS config, `.qa/playwright.qa.config.ts`, written at run time: five projects (Desktop Chrome, Desktop
  Safari = WebKit on macOS, Desktop Firefox, Mobile Chrome, Mobile Safari), `locale: 'ar-SA'`, `timezoneId:
  'Asia/Riyadh'`, `testIdAttribute: 'data-testid'`, `forbidOnly`, the base URL in `QA_BASE_URL`, every request through
  the egress proxy. A project config of its own is ignored by the lane — do not rely on it there.
- Environment `local`: starts the app from `qa/local-server.json`
  (`{ "command": ["npm", "run", "dev"], "readyPath": "/", "timeoutSec": 120, "env": {} }`), no secret in `env`.
- Production: Desktop Chrome and `@smoke` only; a test that writes must never carry `@smoke` on a project whose
  production is declared.

## Process

1. Find the scenario: its ref (`AUTH-001`) in Injaz (المشاريع التقنية › الاختبارات) or in `injaz-test-scenarios.json`.
2. Title = intent + `[REF]` + tags: `test('تسجيل الدخول بكلمة مرور صحيحة [AUTH-001] @smoke', …)`. Tags: `@smoke`
   (vital path, high severity on failure), `@critical`, `@regression`, `@readonly` (safe on production).
3. Selectors: `getByRole` with the exact Arabic name, then `getByTestId`. Never CSS chains, `nth()`, `.first()`.
4. Waits: web-first assertions (`await expect(locator).toBeVisible()`). Never `waitForTimeout`, never `networkidle`.
5. Data: a dedicated test account named by its variable (`process.env.QA_ACCOUNT_ADMIN_EMAIL`), never a literal;
   create what the test needs and leave the environment as found.
6. Run it locally on Desktop Chrome, then add the map entry (action 03).

## Test

- The spec runs green with `npx playwright test --project="Desktop Chrome" --grep "\[AUTH-001\]"` against staging.
- `grep -nE "waitForTimeout|networkidle|test\.(only|skip|fixme)|\.first\(\)|\.nth\(" <spec>` prints nothing.
- No literal password, token or `qa_` key in the spec; the account comes from an environment variable.
