---
name: 01-rtl-i18n
description: Arabic and RTL correctness for web and mobile — direction model, mirroring, plurals, digits, dates, currency icon, font metrics. Auto-applies with an ar locale or an Arabic/RTL task; say audit to audit RTL readiness.
argument-hint: "[audit]"
paths:
  - "**/ar.json"
  - "**/ar-*.json"
  - "**/app_ar*.arb"
  - "**/intl_ar*.arb"
  - "messages/ar*"
  - "locales/ar*"
  - "locales/ar/**"
---

# Skill: rtl-i18n

Arabic-grade i18n. Flipping the layout is 20% of the job. Every rule names
the incident class it prevents.

## Defaults: digits, calendar, currency

A project may deviate only by a decision recorded in tech-decisions.md.

- **Western digits 0-9 everywhere, input included** — because mixed digit
  sets broke validation, search and comparisons.
- **Gregorian only** — because the default calendar varies by runtime.
- **One formatting helper** owns every number, date and amount, pinned to
  `nu-latn`, `ca-gregory` and an explicit time zone; no `Intl` or
  `toLocaleString` call outside it — because per-call defaults drift
  (`references/formatting.md`).
- Normalise Arabic-Indic and Persian digits to 0-9 on every input, before
  validation — because pasted and keyboard digits fail numeric checks.
- **Currency is always the SVG icon component**, never a Unicode character
  or font glyph — because fallback fonts lack it. Never ﷼ (U+FDFC is another
  currency). Placement: the rendered example in `references/sar.md`.

## Layout (web)

- Logical properties only (`margin-inline-start`, `inset-inline-end`,
  `text-align: start`; Tailwind `ms-*`/`pe-*`/`start-*`) — because a physical
  `left/right` stays invisible until the other direction is tested.
- `dir` on `<html>` from the locale, passed again to every portal/overlay
  root — because portalled content loses the document direction.
- `dir="auto"` on user-generated text, on the text element (not the table
  cell), never on an empty input — because caret and placeholder jump sides.
- Never `flex-row-reverse` "for RTL" — because flex and grid already mirror.

## Layout (React Native)

Read `references/react-native-rtl.md` before the first RN screen.

- Choose the direction model at project start and record it: **Arabic-only
  = forced RTL**; **bilingual = `allowRTL` following the language + reload,
  never `forcesRTL`** — because mixed models double-flipped for months.
- Never mirror the root view with a transform (forbidden for new projects)
  — because every modal, icon, list and input then needs its own exception.
- `start`/`end` style props only; ship the ban on physical props as a lint
  rule, not as prose.
- `writingDirection` at block level only, never on a text run; isolate
  mixed fragments with bidi isolates — because iOS reorders the paragraph.
- Explicit `textAlign` on every `TextInput` — because inputs ignore
  inherited direction.

## What flips and what doesn't

- **Flip**: back/forward icons (chosen by intention, not by arrow name),
  chevrons, progress, carousel order, stepper flow.
- **Never flip**: logos, clocks, media controls, code blocks, maps,
  checkmarks, phone numbers.
- **Phone input is an LTR object** on an RTL screen: recipe in
  `references/rtl-checklist.md`.

## Text and fonts

- Arabic has **6 CLDR plural categories**: every count string uses ICU
  plural syntax and names the set, not the statistic.
- letter-spacing 0 on Arabic (tracking breaks joining); line-height
  ~1.6–1.8; UI fonts with a Latin subset.
- **Mobile metrics check (mandatory)**: `python3
  ${CLAUDE_PLUGIN_ROOT}/skills/01-rtl-i18n/assets/font-metrics.py check <fonts>`
  before the first device build and after every font bump; `CLIP` = the
  device cuts the ي dots (`references/arabic-font-metrics.md`).
- CSV for Arabic: BOM, always quoted — because spreadsheets show mojibake.

## Flutter

Read `references/flutter-rtl.md` before any Flutter UI with an `ar` locale:
`EdgeInsetsDirectional`, ARB + `gen_l10n`, an Arabic font family.

## Audit mode (`audit` argument)

Report, per finding, file + evidence + fix: physical properties, strings
outside the i18n layer, counts without plural syntax, wrongly flipped icons,
letter-spacing on Arabic, formatting outside the helper, non-Latin digits or
a non-Gregorian calendar without a recorded exception, a currency character,
`writingDirection` on a text run. Checklist: `references/rtl-checklist.md`.

## Test

- Code written under this skill has no physical `left|right|ml-|mr-|pl-|pr-`
  on a directional element, no letter-spacing on Arabic text, and ICU
  plurals with the six Arabic categories.
- `grep -rnE "numberingSystem: *'arab'|nu-arab|ca-islamic|forcesRTL|﷼"`
  finds nothing outside a recorded exception; every `Intl.` call sits in the
  formatting helper; the amount renders as in `references/sar.md`.
- An RN project names its direction model in tech-decisions.md.
- No shipped Arabic font reports `CLIP` or `NO-ARABIC`; the check is
  recorded in the release log.
