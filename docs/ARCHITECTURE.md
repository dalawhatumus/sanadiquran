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
| `site/` | The public web pages for Google Play (privacy policy, terms, account deletion), published to GitHub Pages by `.github/workflows/pages.yml`. |
| `test/` | Widget and unit tests (`flutter test`). |
| `tools/` | One-off generators (e.g. the mushaf line widths). |

Large screens are split into `part` files next to them. For example,
`mushaf_screen.dart` has `mushaf_bars.dart`, `mushaf_ayah_menu.dart` and
`mushaf_go_to.dart`, and `chat_screen.dart` has `chat_bubbles.dart` and
`chat_composer.dart`.

## Backend

`Backend` (in `backend/backend.dart`) is the one interface screens use. It
combines `ChatApi`, `CallApi`, `LessonApi`, `AdminApi` (pausing
accounts and the admin overview), `TeacherDirectoryApi` (the teacher list)
and `PhotoApi` (own profile photos). There are two
implementations:

- `DemoBackend`: in memory, used for demo mode (no Firebase settings) and
  all tests.
- `FirebaseBackend`: Firestore and Firebase Auth. The chat, call and lesson
  parts are mixins in `firestore_chat.dart`, `firestore_calls.dart`,
  `firestore_lessons.dart`, `firestore_admin.dart`, `firestore_teachers.dart`
  and `firestore_photos.dart`.

Live data for the signed-in user goes through `perUser`
(`backend/user_stream.dart`). It switches immediately when someone signs in
or out, and restarts a stream that fails, so changes made on another phone
always arrive.

Voice notes, recitation samples and own profile photos are stored as
Firestore blobs (no paid Storage). A photo's `avatar` value is
`photo:{uid}:{version}`, so every place that shows a picture finds it and
fetches it again only when it changes (`photoProvider`, cached on the
phone). Calls are WebRTC audio, signalled through Firestore.

**Matching.** "Recite now" rings free teachers of the student's gender one
at a time (`rankCandidates` in `backend/calls.dart`): the teacher the
student chose, then favourites, then teachers they had lessons with (most
recent first), then those who have taught least today. The rules allow a
call to ring only approved teachers whose application gender matches.

**Ayah of the day** (`features/quran/ayah_of_day.dart`, data in
`daily_ayahs.dart`): one ayah a day with a theme and meaning, on the home
screens and as a notification. The next 30 days are scheduled on the phone
each time the app opens (each day's text differs).

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
- **Native bits** (Android, `MainActivity.kt` and `AvailabilityService.kt`)
  are reached only through `core/background.dart` and `core/screen.dart`,
  which never throw: keep-screen-on during calls, showing over the lock
  screen while a call rings, the teacher's background service, and Back
  moving the app to the background while a teacher is available.
- **Notifications** all go through `Reminders` (`core/reminders.dart`).
- **Confirmations:** use `confirm(context, ...)` from `widgets/dialogs.dart`.

## Checks before a release

```
flutter analyze
flutter test
cd firebase/test && npm install && npm test   # rules, against the Firestore emulator
```
