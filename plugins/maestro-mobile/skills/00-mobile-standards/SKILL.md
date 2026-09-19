---
name: 00-mobile-standards
description: React Native / Expo standards — project structure, navigation, state, performance, platform conventions. Auto-applies when building or reviewing RN/Expo code. Not for Flutter (04-flutter-standards), not for web (maestro-web), not for RTL depth (01-rtl-i18n).
user-invocable: false
paths:
  - "app.json"
  - "app.config.{js,ts}"
  - "eas.json"
  - "expo-env.d.ts"
  - "metro.config.*"
  - "app/**/*.tsx"
  - "app/_layout.tsx"
  - "android/**"
  - "ios/**"
  - "**/*.native.*"
---

# Skill: mobile-standards

Binding conventions for RN/Expo work. Apply silently while building; cite the
violated rule when reviewing.

## Stack defaults

- **Expo with CNG/prebuild** (no committed `android/` `ios/` unless needed)
  and expo-router (file-based). Bare only with a written reason in
  tech-decisions.md.
- TypeScript strict. Zod at every boundary (API responses, deep links, storage).
- State: server state → TanStack Query; local UI state → component state;
  the rare true-global → Zustand. No Redux by default.
- Styling: StyleSheet or NativeWind — one per project, follow what exists.

## Non-negotiables

- **New Architecture is the only architecture on RN 0.82+ / SDK 54+**: every
  native lib must support it (check before adding).
- Every screen handles the 4 states: loading, empty, error (with retry), data.
- Lists: FlatList/FlashList with stable `keyExtractor`; row components
  memoized; never `.map()` for long scrollables.
- Animations: Reanimated worklets or `Animated` with `useNativeDriver: true`;
  never JS-thread animation loops.
- Images: expo-image (caching, placeholders), explicit dimensions.
- Safe areas via react-native-safe-area-context — never hardcoded insets.
- Touch targets >= 44pt. Test on a small device profile, not just the simulator default.
- Secrets: never in the JS bundle — `EXPO_PUBLIC_` only for genuinely public values.
- Deep links validated with Zod before navigation (injection surface).
- OTA updates (expo-updates): runtime version policy set; never ship a native
  module change over OTA.

## Release checklist trigger

Before any store submission talk: versionCode/buildNumber bumped, permissions
justified in the manifest, RTL verified if `ar` supported (01-rtl-i18n),
crash reporting wired (Sentry), privacy manifest fields current.

## Test

A review of RN/Expo code under this skill cites the violated rule by name for
each finding (e.g. "Non-negotiables: lists"), and code written under it leaves
no long scrollable rendered with `.map()`, no hardcoded inset, and no secret
outside `EXPO_PUBLIC_`-safe values.
