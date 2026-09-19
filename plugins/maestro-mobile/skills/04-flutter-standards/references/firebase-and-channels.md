# Firebase and platform channels in Flutter

Reference of `maestro-mobile:04-flutter-standards`. Load when the project
declares `firebase_*` packages or a `MethodChannel`/`EventChannel`.

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
