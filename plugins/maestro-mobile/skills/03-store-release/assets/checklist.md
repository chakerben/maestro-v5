# Store release checklist — <app> <version> (<platform>)

**Verdict**: <GO | NO-GO (n blocking)>   · date: <yyyy-mm-dd> · tag: <vX.Y.Z>

## 1. Build (blocking)

- [ ] Working tree clean, commit tagged (`maestro-vcs:02-release`)
- [ ] `version` bumped; iOS `buildNumber` / Android `versionCode` strictly greater than the last store build
- [ ] Production env: no `EXPO_PUBLIC_` value pointing at staging; API base URL is production
- [ ] Hermes enabled; release build starts in < 3 s on a low-end device profile
- [ ] Crash reporting (Sentry) wired with the release version and source maps uploaded
- [ ] OTA (expo-updates) runtime version policy matches; no native change since the last runtime version, or a new runtime version is set
- [ ] Deep links / universal links verified on a physical device
- [ ] Secrets: none in the bundle (`grep -r "sk_live\|AKIA" dist/` clean)

## 2. Compliance (blocking)

- [ ] Every requested permission has a justification here AND a purpose string in the manifest (`NSCameraUsageDescription`, `android.permission.*`)
- [ ] Account deletion available in-app when accounts exist (Apple 5.1.1(v), Play policy)
- [ ] Privacy policy URL live, in the app's languages; privacy manifest (iOS) / data-safety form (Play) answers match the SDKs actually present
- [ ] Payments: digital goods through IAP; physical goods/services (donations, bookings, deliveries) through the project's PSP (Moyasar, etc.) — the classification is written here with the reasoning
- [ ] Sign in with Apple offered when any third-party social login is
- [ ] Age rating questionnaire answered from the actual features (UGC, chat, gambling-like mechanics, ads)
- [ ] Export compliance (encryption) answered

## 3. Store listing

- [ ] Title, subtitle, description in every shipped language (ar first when the market is KSA)
- [ ] Screenshots per device class, per language — Arabic ones taken in RTL with real Arabic content
- [ ] Preview video (optional) has no third-party trademarks
- [ ] Support URL and contact answer within the review window
- [ ] Demo account for the reviewer, with data, documented in review notes (if login required)
- [ ] What's-new text written for users, not from the changelog

## 4. KSA specifics

- [ ] Hijri date display verified where the product shows dates to Saudi users
- [ ] SAR rendering: SarIcon, not the ﷼ glyph; amounts formatted per locale decision
- [ ] Arabic typography: no letter-spacing, line-height ≥ 1.6, diacritics not clipped
- [ ] Numerals decision (arab vs latn) applied consistently and recorded in tech-decisions.md
- [ ] Regulatory content present when the domain requires it (CST/PDPL notices, charity licence number for donation apps, VAT number on receipts)
- [ ] Phone/OTP flows tested with a +966 number; SMS sender ID registered

## 5. Final

- [ ] Fresh install → onboarding → main flow → logout, on iOS and Android physical devices, in `ar` and the second locale
- [ ] Offline start does not crash; airplane-mode screens show the error state with retry
- [ ] Rollback plan written: which OTA/rollback lever, who can trigger it
- [ ] Human doing the upload named; review notes pasted in the console

## Rejection (when applicable)

<store text> → <checklist item> → <answer / fix>
