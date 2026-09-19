---
name: 01-rtl-i18n
description: Arabic and RTL correctness for web and mobile — layout mirroring, Arabic typography and plurals, Hijri dates, numerals, currency. Auto-applies when the project has an ar locale or the task mentions Arabic/RTL. Use also to audit RTL readiness. The deepest Maestro expertise — read references/rtl-checklist.md before large RTL work.
argument-hint: "[audit]"
paths:
  - "**/ar.json"
  - "**/ar/**"
  - "**/*.arb"
  - "messages/ar*"
  - "locales/ar*"
  - "lib/l10n/**"
---

# Skill: rtl-i18n

Arabic-grade i18n. "Flipping the layout" is 20% of the job — this skill
covers the other 80%.

## Layout rules (web)

- **Logical properties ONLY**: `margin-inline-start`, `padding-inline-end`,
  `inset-inline-start`, `border-start-start-radius`, `text-align: start`.
  Physical `left/right` in styles is a review finding.
- Tailwind: use `ms-*`/`me-*`/`ps-*`/`pe-*`/`start-*`/`end-*` utilities —
  never `ml-*`/`mr-*` in a multilingual codebase.
- `dir` set on `<html>` from the locale; `dir="auto"` on user-generated
  content containers (a bidi comment field renders correctly regardless of
  the surrounding page direction).
- Flexbox/Grid mirror automatically under `dir=rtl` — do NOT add
  `flex-row-reverse` "for RTL"; that double-flips.

## Layout rules (React Native)

- `I18nManager.allowRTL(true)` + `forceRTL` per locale — **requires an app
  restart** to apply; design the language switcher accordingly (Expo:
  `expo-updates` reload).
- Native flags: `android:supportsRtl="true"` in AndroidManifest; Expo: the
  `expo-localization` config plugin (RTL on by default; `supportsRTL` /
  `forcesRTL` options) plus `extra.supportsRTL: true` for Expo Go.
- Use `start`/`end` style props (`marginStart`, `paddingEnd`) — RN maps them
  per direction. `writingDirection` for text alignment edge cases.
- `flexDirection: 'row'` auto-mirrors under RTL. Never hand-reverse.

## What flips and what doesn't

- **Flip**: directional arrows, chevrons, back icons, progress direction,
  carousel order, stepper flow.
- **Never flip**: logos, clocks, media playback controls (play stays ▶),
  phone numbers, code blocks, maps, checkmarks.

## Text, plurals, numbers, dates

- Arabic has **6 CLDR plural categories** (zero, one, two, few, many, other).
  Every count string uses ICU plural syntax — a hardcoded "s" suffix is a bug.
- Numerals: decide per market — `ar-SA` commonly uses Arabic-Indic digits
  (٠١٢٣) in consumer contexts. Control via
  `Intl.NumberFormat('ar-SA', { numberingSystem: 'arab' | 'latn' })` and
  record the choice in tech-decisions.md.
- Dates: Saudi context often requires **Hijri** —
  `new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura')`. Dual display
  (Hijri + Gregorian) for legal/official documents.
- Currency: format with `Intl.NumberFormat(…, { currencyDisplay: 'code' })`
  and replace the `SAR` token by `assets/sar-icon.svg` (see
  `references/sar.md`). U+20C1 SAUDI RIYAL SIGN (Unicode 17, Sept 2025) as
  text only when every font in the render path has the glyph; never ﷼.

## Fonts

- UI: Cairo, Tajawal, or IBM Plex Sans Arabic (include Latin subset for
  mixed text). Print/PDF: Amiri or Noto Naskh Arabic.
- Line-height: Arabic needs ~1.6–1.8 (taller than Latin defaults) — check
  clipping of diacritics and descenders.
- letter-spacing MUST be 0 for Arabic — tracking breaks cursive joining.

## Flutter

The rules above are web/RN. Flutter has its own directional APIs, its own
string system (ARB) and a specific font trap: read
`references/flutter-rtl.md` **before** any Flutter UI in a project with an
`ar` locale. In one line: `EdgeInsetsDirectional`, never
`EdgeInsets.only(left:)`; ARB + `gen_l10n`, never an `isArabic` ternary; a
Latin font has no Arabic glyphs.

## Audit mode (`audit` argument)

Scan the scope and report: physical CSS properties, hardcoded strings
outside the i18n layer, count strings without plural syntax, icons flipped
wrong, `letter-spacing` on Arabic text, date/number formatting without
locale. Each finding: file, evidence, fix. See `references/rtl-checklist.md`.

## Test

- Code written under this skill contains no physical `left|right|ml-|mr-|pl-|pr-`
  property on a directional element, no `letter-spacing` other than 0 on
  Arabic text, and every count string uses ICU plural with the six Arabic
  categories.
- `audit` output lists each finding as file:line + quoted evidence + fix, and
  the arab-vs-latn digits choice is either read from tech-decisions.md or
  flagged as "decision needed" — never assumed.
