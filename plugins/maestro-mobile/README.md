# maestro-mobile

Mobile + Arabic — the Maestro differentiator.

## Skills

- `00-mobile-standards` — RN/Expo conventions: CNG/prebuild, New
  Architecture only, 4 states, FlashList, Reanimated, safe areas, OTA policy
- `01-rtl-i18n` — the deep one: logical properties, what flips/what doesn't,
  6 Arabic plural categories, digits 0-9 and Gregorian dates through one
  formatting helper (`references/formatting.md`), the two React Native
  direction models (`references/react-native-rtl.md`), SAR icon
  (`references/sar.md`), Arabic typography (line-height, letter-spacing:0),
  font metrics (`assets/font-metrics.py`, `references/arabic-font-metrics.md`).
  Ships `references/rtl-checklist.md`, `references/flutter-rtl.md`,
  `references/react-native-rtl.md`, `references/formatting.md`,
  `references/sar.md` and `assets/sar-icon.svg`.
- `02-pdf-rtl` — the reliable Arabic PDF route (browser print engine),
  embedded fonts, bidi-safe invoice templates, shaping smoke tests, ZATCA
  QR/phases (`references/zatca.md`)
- `03-store-release` — go/no-go submission checklist with evidence: build,
  compliance (permissions, account deletion, IAP vs PSP), listing, KSA
  specifics (digits and dates, SAR icon, +966 OTP, regulatory notices); works a rejection
  text back to the item it violates
- `04-flutter-standards` — Flutter/Dart: structure, state out of widgets,
  dispose/async discipline (where Flutter apps actually break), 4 states,
  perf; Firebase named instances and platform channels in
  `references/firebase-and-channels.md`
- `06-eas-build-and-ota` — store/tester binaries and over-the-air updates:
  update URL and runtime policy before the first build, clean-clone builds,
  no native change over the air, explicit env at export, tester builds on
  the acceptance environment by default, delivery claims proven by the
  update list
