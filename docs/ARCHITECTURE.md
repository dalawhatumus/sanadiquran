# Sanadi: how the code is organised

A Flutter app (Android first), Arabic and English, built for elderly users.
State is held in Riverpod providers and screens are routed with go_router.
The server is Firebase (Auth + Firestore) on the free Spark plan.

## Folders

| Folder | What lives there |
| --- | --- |
| `lib/main.dart`, `lib/app.dart` | Start-up: Firebase (if configured), settings, theme, router. |
| `lib/core/` | App-wide pieces with no screens: settings, strings (Arabic/English), theme, router, input limits, reminders, local files, logging, connectivity, version. |
| `lib/backend/` | Everything that talks to the server. See "Backend" below. |
| `lib/features/<area>/` | One folder per area of the app: `onboarding`, `student`, `teacher`, `quran`, `athkar`, `messages`, `call`, `lessons`, `settings`, `admin`, `shell` (the tab bar). |
| `lib/widgets/` | Shared widgets. Import `widgets/ui.dart` to get them all (buttons, cards, text, layout, dialogs, toasts, icons). |
| `assets/` | Quran text and page layout, athkar, fonts, icons, avatars. |
| `firebase/` | Firestore security rules, indexes and their emulator tests. |
| `test/` | Widget and unit tests (`flutter test`). |
| `tools/` | One-off generators (e.g. the mushaf line widths). |

Large screens are split into `part` files next to them. For example,
`mushaf_screen.dart` has `mushaf_bars.dart`, `mushaf_ayah_menu.dart` and
`mushaf_go_to.dart`, and `chat_screen.dart` has `chat_bubbles.dart` and
`chat_composer.dart`.

## Backend

`Backend` (in `backend/backend.dart`) is the one interface screens use. It
combines `ChatApi`, `CallApi` and `LessonApi`. There are two
implementations:

- `DemoBackend`: in memory, used for demo mode (no Firebase settings) and
  all tests.
- `FirebaseBackend`: Firestore and Firebase Auth. The chat, call and lesson
  parts are mixins in `firestore_chat.dart`, `firestore_calls.dart` and
  `firestore_lessons.dart`.

Live data for the signed-in user goes through `perUser`
(`backend/user_stream.dart`). It switches immediately when someone signs in
or out, and restarts a stream that fails, so changes made on another phone
always arrive.

Voice notes and recitation samples are stored as Firestore blobs (no paid
Storage). Calls are WebRTC audio, signalled through Firestore.

## Conventions

- **Text:** every string the user sees lives in `core/strings.dart` as
  `S.of(context).name`, with Arabic in feminine and masculine forms where
  needed.
- **Layout rules:** no word is ever broken across lines (`WordSafeText`).
  An arrow pointing right means "proceed" in both languages (`Arrows`).
- **Input limits:** what people can type is limited by `core/limits.dart`,
  which must stay within the limits in `firebase/firestore.rules`. A test
  checks this.
- **Logging:** use `logIssue()`. It writes in debug builds only.
- **Confirmations:** use `confirm(context, ...)` from `widgets/dialogs.dart`.

## Checks before a release

```
flutter analyze
flutter test
cd firebase/test && npm install && npm test   # rules, against the Firestore emulator
```
