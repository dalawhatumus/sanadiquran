# Sanadi (سَنَدي)

A free Quran memorisation app connecting elderly students with volunteer teachers of the same gender over live audio calls. Built as sadaqah jariyah.

- **Platform:** Android first (Flutter), iOS later
- **Package name:** `sanadi.quran`
- **Languages:** Arabic, English

## Docs
- [Product spec](docs/SPEC.md)
- [Design prompts](docs/DESIGN_PROMPTS.md)
- [Claude Design brief](docs/CLAUDE_DESIGN_BRIEF.md)
- Logo: [assets/brand](assets/brand)

## Get the test app on your phone
1. On your phone, open **https://github.com/dalawhatumus/sanadiquran/releases/latest** (signed in to GitHub).
2. Under **Assets**, tap **`sanadi-build-N.apk`** to download it.
3. Open the downloaded file and tap **Install**. Allow "Install unknown apps" if asked; if Play Protect warns, tap **More details → Install anyway**.

Every successful build publishes a new release, so that link always has the newest APK.

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
  core/        settings (language, role), theme, router
  features/    one folder per area: onboarding, student, teacher, quran, athkar, messages, settings
  l10n/        app_en.arb / app_ar.arb translations (code is generated from these)
  widgets/     shared UI pieces
test/          widget tests
```

Every push runs analyse, tests and an APK build on GitHub Actions.
