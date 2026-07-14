---
name: 00-mobile-standards
description: React Native / Expo standards for any mobile work — project structure, navigation, state, performance, and platform conventions. Auto-applies whenever building or reviewing RN/Expo code. Not for web (maestro-web) or pure RTL questions (01-rtl-i18n).
user-invocable: false
---

# Skill: mobile-standards

Binding conventions for RN/Expo work. Apply silently while building; cite the
violated rule when reviewing.

## Stack defaults

- **Expo managed workflow** with expo-router (file-based). Bare only with a
  written reason in tech-decisions.md.
- TypeScript strict. Zod at every boundary (API responses, deep links, storage).
- State: server state → TanStack Query; local UI state → component state;
  the rare true-global → Zustand. No Redux by default.
- Styling: StyleSheet or NativeWind — one per project, follow what exists.

## Non-negotiables

- **Hermes enabled.** Check app.json/gradle before perf work.
- Every screen handles the 4 states: loading, empty, error (with retry), data.
- Lists: FlatList/FlashList with stable `keyExtractor`; row components
  memoized; never `.map()` for long scrollables.
- Animations on the UI thread (Reanimated) — no JS-thread `Animated` loops.
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
