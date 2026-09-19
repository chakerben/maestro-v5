# maestro-mobile

Mobile + Arabic — the Maestro differentiator.

## Skills

- `00-mobile-standards` — RN/Expo conventions: CNG/prebuild, New
  Architecture only, 4 states, FlashList, Reanimated, safe areas, OTA policy
- `01-rtl-i18n` — the deep one: logical properties, what flips/what doesn't,
  6 Arabic plural categories, Hijri dates, arab/latn numerals, SAR icon
  (`references/sar.md`), Arabic typography (line-height, letter-spacing:0).
  Ships `references/rtl-checklist.md` and `references/flutter-rtl.md`.
- `02-pdf-rtl` — the reliable Arabic PDF route (browser print engine),
  embedded fonts, bidi-safe invoice templates, shaping smoke tests, ZATCA
  QR/phases (`references/zatca.md`)
- `03-store-release` — go/no-go submission checklist with evidence: build,
  compliance (permissions, account deletion, IAP vs PSP), listing, KSA
  specifics (Hijri, SAR, +966 OTP, regulatory notices); works a rejection
  text back to the item it violates
- `04-flutter-standards` — Flutter/Dart: structure, state out of widgets,
  dispose/async discipline (where Flutter apps actually break), 4 states,
  perf; Firebase named instances and platform channels in
  `references/firebase-and-channels.md`
