# Sanadi (سَنَدي)

A free Quran memorisation app connecting elderly students with volunteer teachers of the same gender over live audio calls. Built as sadaqah jariyah.

- **Platform:** Android first (Flutter), iOS later
- **Package name:** `sanadi.quran`
- **Languages:** Arabic, English

## Docs
- [Product spec](docs/SPEC.md)
- [Design prompts](docs/DESIGN_PROMPTS.md)
- [Claude Design brief](docs/CLAUDE_DESIGN_BRIEF.md)
- [Brand sheet](assets/brand/sanadi-brand-sheet.png) · logo files in [assets/brand](assets/brand)

## Get the test app on your phone
1. On your phone, open **https://github.com/dalawhatumus/sanadiquran/releases/latest** (signed in to GitHub).
2. Under **Assets**, tap **`sanadi-build-N.apk`** to download it.
3. Open the downloaded file and tap **Install**. Allow "Install unknown apps" if asked; if Play Protect warns, tap **More details → Install anyway**.

Every successful build publishes a new release, so that link always has the newest APK.

### What works in this test build
Built to match the approved Claude Design screens (batches 1–3):
- **Onboarding 1–16:** splash, language, welcome, role, gender, name, microphone and notification permissions (real Android prompts, with the "turned off" help screen), welcome tour, and the 5-step teacher application with the pending and not-approved homes.
- **Student:** home, connecting, in call, end-call check, call ended with rating, My progress, Teacher's notes.
- **Teacher:** home with the availability switch, incoming call, in call, call ended with optional notes.
- **Quran:** all 114 surahs from the official KFGQPC Hafs text and font, *Large text* and *Mushaf page* modes (portrait and landscape), long-press ayah menu, bookmarks, go to page or surah.
- **Athkar:** morning, evening, after salah, tasbeeh, before sleep and on waking, with a tap counter.
- Arabic written for the user's gender, dark mode, and layouts checked at 200% text size.

Not real yet (simulated): Google sign-in, calls, notes delivery, messages, reminders and audio. These come with Firebase and calling. **Settings → Testing tools** lets you switch between student and teacher, approve or reject a teacher application, and try an incoming call.

## Develop locally (optional)
Needs Flutter 3.47.6 and the Android SDK (via Android Studio).

```sh
flutter pub get
flutter run          # phone connected over USB with USB debugging on
flutter analyze      # lint
flutter test         # widget tests
```

### Project layout
```
lib/
  core/        settings, theme (design tokens), router, strings (English + gender-aware Arabic)
  features/    one folder per area: onboarding, student, teacher, call, quran, athkar, messages, settings
  widgets/     shared UI pieces (buttons, cards, icons)
assets/
  fonts/       Tajawal, Montserrat, Noto Naskh Arabic, KFGQPC Hafs (Quran)
  quran/       KFGQPC Hafs v18 text (see its README)
  icons/       custom icons from the design system
test/          widget tests, including a 200% text-size sweep of every screen
```

Every push runs analyse, tests and an APK build on GitHub Actions.
