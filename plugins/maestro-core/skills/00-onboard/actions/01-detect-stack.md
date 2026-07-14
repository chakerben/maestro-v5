# 01 - Detect stack

Inspect the project and produce a structured stack profile.

## Input

The project root (current working directory).

## Output

A stack profile listing detected technologies, printed as a table. Used by
actions 02 and 03 to decide what to install.

## Process

1. **Language & runtime.** Check for `package.json` (Node), `pyproject.toml`
   or `requirements.txt` (Python), `pubspec.yaml` (Flutter/Dart).
2. **Framework signals.** In `package.json` dependencies, look for:
   `next` (Next.js), `react-native` / `expo` (mobile), `@nestjs/core` (NestJS),
   `nuxt` (Nuxt), `vue` (Vue).
3. **Data layer.** `prisma/` directory or `@prisma/client` dep → Prisma.
   `drizzle` dep → Drizzle. `supabase` dep → Supabase.
4. **Auth.** `@clerk/` deps → Clerk. `next-auth` / `@auth/` → Auth.js.
5. **Styling & UI.** `tailwindcss` → Tailwind. Check for `styled-components`.
6. **Testing.** `jest`, `vitest`, `@playwright/test` in devDependencies.
7. **i18n / RTL signals.** `next-intl`, `i18next`, `react-i18next` deps, or an
   `ar` locale folder anywhere under `locales/`, `messages/`, `i18n/` → the
   project is multilingual; flag `rtl: likely` if an `ar` locale exists.
8. **VCS & CI.** `.git/` present? `.github/workflows/` present?
9. Print the profile as a compact table and state which plugin
   recommendations it will drive.

## Test

- The profile lists at least: language, framework(s), data layer, testing,
  i18n status, VCS status — each with `detected` / `not found`.
- No file was created or modified.
