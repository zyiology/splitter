# Development Setup

## Prerequisites
*   Flutter SDK
*   Android Studio (recommended) or VS Code
*   Firebase Project (configured with Auth, Firestore, Functions)

## Building the App

### Android
This is the primary development platform.
```bash
flutter run
# or
flutter build apk
```

### Other Platforms
Folders for iOS, Web, Linux, etc., exist but are **untested** standard templates.

## specific Setup Keys
*   **Firebase**: ensure `google-services.json` is present in `android/app/`.
*   **Deep Links**: configured in `AndroidManifest.xml` (Android) and `Info.plist`/Entitlements (iOS) to handle `https://splitter-2e1ae.web.app/join`.
