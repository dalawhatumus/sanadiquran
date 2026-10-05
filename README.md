# Sanadi (سَنَدي)

A free Quran memorisation app connecting elderly students with volunteer teachers of the same gender over live audio calls. Built as sadaqah jariyah.

- **Platform:** Android first (Flutter), iOS later
- **Package name:** `sanadi.quran`
- **Languages:** Arabic, English

## Docs
- [Product spec](docs/SPEC.md)
- [Design prompts](docs/DESIGN_PROMPTS.md)

## Get the test app on your phone
1. Open the **Actions** tab on GitHub and click the latest green **Android build** run.
2. Scroll to **Artifacts** and download **sanadi-apk** (a zip).
3. Unzip it on your phone and tap `app-release.apk` to install. Allow "Install unknown apps" if asked.

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
