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

## Async & lifecycle (where Flutter apps actually break)

- Every `StreamSubscription`, `Timer`, `AnimationController`,
  `TextEditingController`, socket and recorder is **cancelled/disposed** in
  `dispose()`. A leaked audio or socket subscription survives navigation and
  double-delivers.
- `if (!mounted) return;` after every `await` before touching state or
  context. Never `BuildContext` across an async gap.
- Background/foreground: a long-running capture uses a foreground service
  (`flutter_foreground_task`) and re-checks permissions on resume; audio and
  wakelock are released on `AppLifecycleState.paused` unless the feature is
  explicitly a background one.
- Errors from streams are handled (`onError`), not left to crash the zone.

## Firebase

- **Never assume the default instance** when the project uses a named
  database or a secondary app: `FirebaseFirestore.instanceFor(app: …,
  databaseId: '<id>')`. Put it behind ONE accessor in `services/` — a
  `FirebaseFirestore.instance` anywhere else is a silent wrong-database bug.
- Reads are paginated and scoped (`limit`, `where`) — a collection listener
  without bounds is a bill.
- Security rules are the boundary, not the client: client-side filtering is
  not authorization. Auth tokens never travel in file metadata, URLs or logs.
- FCM topics and payload keys live in a constants file shared with the
  backend, not as string literals across screens.

## Platform channels

- One Dart bridge class per channel, in `utils/` or `services/`, with the
  channel name as a `static const`. Every native call is wrapped in
  try/catch with a documented fallback when the platform lacks the feature
  (iOS vs Android PiP, overlay permissions).

## Performance

- `const` constructors wherever possible; `ListView.builder`/`SliverList`
  for any list that can grow; `RepaintBoundary` around animated subtrees.
- Images sized explicitly, cached; no decoding in `build()`.
- `flutter analyze` clean before commit — warnings included.

## Secrets & config

- No key, URL or token hardcoded in `lib/`: `--dart-define` or a config
  service, with the fallback documented. Anything in the Dart bundle is
  public — treat it as such.

## Test

- Code written under this skill leaves no `StreamSubscription`, controller
  or timer without a matching cancel/dispose, and no `BuildContext` used
  after an `await` without a `mounted` check.
- No new `FirebaseFirestore.instance` when the project declares a named
  database; no secret literal added under `lib/`.
- `flutter analyze` reports zero issues on the changed files.
