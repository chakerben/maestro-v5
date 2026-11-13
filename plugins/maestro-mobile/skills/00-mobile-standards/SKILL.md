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
  - "android/app/src/main/AndroidManifest.xml"
  - "ios/Podfile"
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

## Session, async, navigation

Each rule names its incident class. Ship the relative-push ban, the
no-test-under-routes check and the no-mock-in-bundle assertion as lint rules
or tests, not as prose.

- Only an explicit 401/403 ends a session; a network failure or a 5xx never
  clears tokens — because users were logged out in tunnels.
- One `endIdentity()` clears tokens and every cache; logout and every 401
  path call it — because the next account saw the previous one's data.
- Every awaited call handles not-ok, checks an alive ref after the await,
  holds a busy ref against double taps and a sequence guard against stale
  responses — because of crashes on unmounted screens and out-of-order data.
- No side effects in render — because of duplicate navigations and requests.
- Absolute paths in `router.push`; `dismissTo` to return to a screen —
  because relative pushes misroute and `navigate` stacks a duplicate.
- No test or helper file under the routes folder — because the router turns
  it into a route.
- Portal providers (sheets, modals) sit innermost, below the app's context
  providers; on iOS a child overlay opens inside its parent modal — because
  portalled content lost its context and sibling modals stayed invisible.
- No padding on `KeyboardAvoidingView`; keyboard behaviour is verified on an
  Android emulator and the newest iOS — because a fix inferred on one
  platform failed on the other.

## Data

- Server entities are never client-only state — because local lists did not
  follow deletions and moderation.
- Stale-while-revalidate: revalidate on mount, foreground, reconnect and
  focus; never a spinner over data already shown; persist only safe keys.
- No mock data reachable in a production build (dev flag and shell env
  only; assert the mock module is absent from the bundle) — because testers
  saw demo numbers.
- A labelled pressable is one accessibility element exposing its value —
  because e2e selectors and screen readers saw fragments.
- Pure logic lives in plain files beside the screen, each with a unit test.

## Release checklist trigger

Before any store submission talk: versionCode/buildNumber bumped, permissions
justified in the manifest, RTL verified if `ar` supported (01-rtl-i18n) —
including the Arabic font metrics check (`python3
${CLAUDE_PLUGIN_ROOT}/skills/01-rtl-i18n/assets/font-metrics.py check`, no
`CLIP`) — crash reporting wired (Sentry), privacy manifest fields
current.

## Test

A review of RN/Expo code under this skill cites the violated rule by name for
each finding (e.g. "Non-negotiables: lists"), and code written under it leaves
no long scrollable rendered with `.map()`, no hardcoded inset, no secret
outside `EXPO_PUBLIC_`-safe values, no relative `router.push`, no test file
under the routes folder, and no token cleared on a network error or a 5xx.
