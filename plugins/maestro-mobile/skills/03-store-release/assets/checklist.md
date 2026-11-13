# Store release checklist — <app> <version> (<platform>)

**Verdict**: <GO | NO-GO (n blocking)>   · date: <yyyy-mm-dd> · tag: <vX.Y.Z>

## 1. Build (blocking)

- [ ] Working tree clean, HEAD is the commit to tag (tag is created after GO via `maestro-vcs:02-release`)
- [ ] `version` bumped; iOS `buildNumber` / Android `versionCode` strictly greater than the last store build
- [ ] Production env: no `EXPO_PUBLIC_` value pointing at staging; API base URL is production
- [ ] Release build starts in < 3 s on a low-end device profile
- [ ] iOS: built with the minimum Xcode/SDK Apple currently accepts for submission (check the current requirement in App Store Connect / Apple developer news)
- [ ] Android: `targetSdkVersion` meets Google Play's current requirement for new apps and updates (check the current Play target API level policy)
- [ ] Android: all native libraries support 16 KB page sizes (Play requirement since 1 Nov 2025 for new apps and updates targeting Android 15+; verify in Android Studio's APK Analyzer or the Play Console pre-launch report)
- [ ] Crash reporting (Sentry) wired with the release version and source maps uploaded
- [ ] OTA (expo-updates) runtime version policy matches; no native change since the last runtime version, or a new runtime version is set
- [ ] Deep links / universal links verified on a physical device
- [ ] Secrets: none in the bundle (`grep -r "sk_live\|AKIA" dist/` clean)

## 2. Compliance (blocking)

- [ ] Every requested permission has a justification here AND a purpose string in the manifest (`NSCameraUsageDescription`, `android.permission.*`)
- [ ] Account deletion available in-app when accounts exist (Apple 5.1.1(v), Play policy), and the Play Data safety form carries the account-deletion web URL
- [ ] Privacy policy URL live, in the app's languages; privacy manifest (iOS) / data-safety form (Play) answers match the SDKs actually present
- [ ] Payments: digital goods through IAP; physical goods/services (donations, bookings, deliveries) through the project's PSP (Moyasar, etc.) — the classification is written here with the reasoning
- [ ] An equivalent privacy-preserving login (Sign in with Apple qualifies) when third-party social login is offered (Apple 4.8)
- [ ] iOS: ATT prompt (`NSUserTrackingUsageDescription`, Apple 5.1.2) when any SDK reads the IDFA; none requested otherwise
- [ ] Age rating questionnaire answered from the actual features (UGC, chat, gambling-like mechanics, ads)
- [ ] Android manifest matches the privacy claim: no permission the listing or the data-safety form denies (read the merged manifest of the release build)
- [ ] Privacy policy and account-deletion URLs answer 200 right now; seed and test accounts are purged from production data the reviewer can see
- [ ] Export compliance answered; `ITSAppUsesNonExemptEncryption` set explicitly in Info.plist / `app.json` (`ios.config.usesNonExemptEncryption`)

## 3. Store listing

- [ ] Title, subtitle, description in every shipped language (ar first when the market is KSA)
- [ ] Screenshots per device class, per language — Arabic ones taken in RTL with real Arabic content
- [ ] Preview video (optional) has no third-party trademarks
- [ ] Support URL and contact answer within the review window
- [ ] Demo account for the reviewer, with data, documented in review notes (if login required); it signs in **without receiving an SMS or e-mail code**
- [ ] The app has its own icon, splash and listing name — none shared with another app of the same developer account (spam rejection, account-wide); unrelated client brands live under separate developer accounts
- [ ] What's-new text written for users, not from the changelog

## 4. KSA specifics

- [ ] Dates are Gregorian and digits 0-9 on every screen and input (a Hijri display or Arabic-Indic digits only as an exception recorded in tech-decisions.md)
- [ ] SAR rendered by the SVG icon component as in `01-rtl-i18n/references/sar.md`; no currency character anywhere
- [ ] Arabic typography: no letter-spacing, line-height ≥ 1.6, diacritics not clipped
- [ ] RN: the direction model is the recorded one (forced RTL for an Arabic-only app; `allowRTL` following the language, no `forcesRTL`, for a bilingual one)
- [ ] Regulatory content present when the domain requires it (CST/PDPL notices, charity licence number for donation apps, VAT number on receipts)
- [ ] Phone/OTP flows tested with a +966 number; SMS sender ID registered

## 5. Final

- [ ] One full pass on a tablet layout (review runs on it even for a phone-only app)
- [ ] Upcoming platform requirements read for this release (minimum SDK, scene lifecycle, deprecations with a date) and written here with their deadline
- [ ] Fresh install → onboarding → main flow → logout, on iOS and Android physical devices, in `ar` and the second locale
- [ ] Offline start does not crash; airplane-mode screens show the error state with retry
- [ ] Rollback plan written: which OTA/rollback lever, who can trigger it
- [ ] Human doing the upload named; review notes pasted in the console

## Rejection (when applicable)

<store text> → <checklist item> → <answer / fix>
