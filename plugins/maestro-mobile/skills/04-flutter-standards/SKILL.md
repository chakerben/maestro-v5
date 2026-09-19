---
name: 04-flutter-standards
description: Flutter/Dart conventions — structure, state out of widgets, async and dispose discipline, Firebase access, platform channels, performance, secrets. Auto-applies when working in a Flutter project (pubspec.yaml, lib/**.dart). Not for React Native/Expo (00-mobile-standards), not for Arabic/RTL depth (01-rtl-i18n covers Flutter's directional APIs and fonts).
user-invocable: false
paths:
  - "pubspec.yaml"
  - "lib/**/*.dart"
  - "test/**/*.dart"
  - "analysis_options.yaml"
---

# Skill: flutter-standards

Binding conventions for Flutter work. Apply silently while building; cite the
violated rule when reviewing. An existing project's own conventions win —
read its CLAUDE.md and `.claude/rules/` first and say so when they differ.

## Structure

- `lib/main.dart` (entry + DI + app shell) · `screens/` or `features/<x>/` ·
  `widgets/` (reusable, no business logic) · `services/` (I/O: API, sockets,
  Firebase, audio) · `models/` · `utils/`.
- **A screen file over ~400 lines is a refactor, not a style opinion.** Pull
  the I/O into a service and the sub-trees into widgets; a widget that both
  streams audio and lays out a screen cannot be tested or reviewed.
- One public widget per file; `part`/`part of` only for generated code.

## State

- State lives **outside** the widget: controller (GetX), notifier (Riverpod),
  bloc — one per project, never two. `setState` is for local, ephemeral UI
  state only (a toggle, a focus flag), never for data from I/O.
- Whatever the choice, the rule is the same: the widget reads state and
  renders; it does not own the socket, the timer or the subscription.
- Rebuild scope: wrap the smallest subtree (`Obx`/`Consumer`/`BlocBuilder`),
  never the whole `Scaffold`.
- Every data screen renders the 4 states: loading, empty, error (with
  retry), data — a `FutureBuilder` with only the success branch is incomplete.

## Async & lifecycle (where Flutter apps actually break)

- Every `StreamSubscription`, `Timer`, `AnimationController`,
  `TextEditingController`, socket and recorder is **cancelled/disposed** in
  `dispose()`. A leaked audio or socket subscription survives navigation and
  double-delivers.
- `if (!context.mounted) return;` (Dart 3) after every `await` before
  touching state or context; `mounted` alone in a `State`. Never a
  `BuildContext` across an async gap.
- Background/foreground: observe with `AppLifecycleListener` (not a hand
  rolled `WidgetsBindingObserver`); a long-running capture uses a foreground
  service (`flutter_foreground_task`) and re-checks permissions on resume;
  audio and wakelock are released on `onPause`/`onHide` unless the feature
  is explicitly a background one.
- Errors from streams are handled (`onError`), not left to crash the zone.

## Firebase & platform channels

Named instances, bounded reads, one bridge class per channel: see
`references/firebase-and-channels.md` when either is in the project.

## Performance

- `const` constructors wherever possible; `ListView.builder`/`SliverList`
  for any list that can grow; `RepaintBoundary` around animated subtrees.
- Images sized explicitly, cached; no decoding in `build()`.
- `flutter analyze` clean before commit — warnings included.

## Secrets & config

- No key, URL or token hardcoded in `lib/`: `--dart-define-from-file`
  (one JSON per environment, git-ignored) or a config service, with the
  fallback documented. Anything in the Dart bundle is public — treat it as
  such.

## Test

- Code written under this skill leaves no `StreamSubscription`, controller
  or timer without a matching cancel/dispose, and no `BuildContext` used
  after an `await` without a `mounted` check.
- No new `FirebaseFirestore.instance` when the project declares a named
  database; no secret literal added under `lib/`.
- `flutter analyze` reports zero issues on the changed files.
