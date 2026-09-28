# AgriNexus AI — Module 1: Farmer + AI Agriculture (Flutter App)

Farmer-facing app: auth, profile, farms, crops, AI plant doctor, pest
identification, crop recommendation, weather, and feedback reporting.

## ⚠️ Verification status (read this first)

Unlike the backend (tested live against a real PostgreSQL database with
23/23 tests passing), **this Flutter code has not been compiled or run** —
the Flutter SDK's download host isn't reachable in the sandbox I built this
in. I did do what static checking I could without the SDK:

- Every file has balanced braces
- Every `t.someKey` localization call used in the UI has a matching entry in
  all three ARB files (en/si/ta), with full key parity across languages
- Every relative `import '...'` resolves to a file that actually exists
- Manually reviewed for the two Flutter API mistakes I know are common
  (`DropdownButtonFormField` param name, `Color.withValues` vs `withOpacity`)

What I *can't* rule out without a real `flutter analyze`/`flutter run`: null-
safety edge cases, exact Provider/context timing issues, or a Flutter-version-specific
API mismatch. **Please run `flutter analyze` and `flutter run` yourself
before trusting this in a demo**, and treat this phase with more scrutiny
than Phase 1/2's backend.

## 1. Setup

If this repo doesn't already have Flutter platform folders (`android/`,
`ios/`) for the frontend:

```bash
cd frontend
flutter create --org com.agrinexus --project-name agrinexus_farmer .
```

This generates `android/`, `ios/`, etc. **without touching** the `lib/`,
`pubspec.yaml`, or `l10n.yaml` already in this delivery — `flutter create`
on an existing directory only fills in missing platform scaffolding.

Then:
```bash
flutter pub get
```

## 2. Generate localization code

The `AppLocalizations` class referenced throughout `lib/` (in
`lib/shared/l10n/app_localizations.dart`) is **generated**, not included in
this delivery — running `flutter pub get` (or `flutter gen-l10n` directly)
reads `l10n.yaml` + the three `.arb` files and generates it automatically,
because `generate: true` is set in `pubspec.yaml`.

## 3. Point the app at your backend

Default assumes an Android emulator hitting `uvicorn` on your host machine:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Other targets:
- iOS simulator / desktop: `--dart-define=API_BASE_URL=http://localhost:8000`
- Physical device: use your machine's LAN IP, e.g. `http://192.168.1.10:8000`

## 4. Required platform permissions (add these yourself after `flutter create`)

**Android** (`android/app/src/main/AndroidManifest.xml`), inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```
Since the dev backend runs on plain HTTP (not HTTPS), also add
`android:usesCleartextTraffic="true"` to the `<application>` tag for local
testing. Remove this once the backend is served over HTTPS.

**iOS** (`ios/Runner/Info.plist`), add:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to photograph plants for AI disease/pest detection</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to select plant photos for AI disease/pest detection</string>
```

## 5. Architecture

```
lib/
  main.dart                    — app entry, routing, auth gate, MaterialApp
  shared/
    api/                       — ApiClient, ApiException, TokenStorage, ApiConfig
    models/                    — Dart classes mirroring backend Pydantic schemas
    services/                  — one per feature area, wraps ApiClient calls
    state/                     — AuthProvider, LocaleProvider (ChangeNotifier)
    widgets/                   — LoadingView, ErrorView, EmptyView, PrimaryButton, etc.
    l10n/                      — app_en.arb, app_si.arb, app_ta.arb (+ generated file)
    routes.dart                — route name constants
  features/
    auth/                      — login_screen.dart, register_screen.dart
    dashboard/                 — farmer_dashboard_screen.dart
    profile/                   — farmer_profile_screen.dart
    farms/                     — my_farms, add_edit_farm, farm_details
    crops/                     — my_crops, add_crop, crop_details
    ai_disease/                — ai_plant_doctor_screen, disease_result_screen
    pest/                      — pest_identification_screen (result shown inline)
    recommendation/            — crop_recommendation_screen
    weather/                   — weather_screen
    feedback/                  — farmer_feedback_screen
```

Every screen goes through the `services/` layer — no screen calls `http`
directly. Auth tokens are stored in `flutter_secure_storage`, refreshed
automatically on a 401 by `ApiClient`.

## 6. Design notes for the team

- `shared/` is exactly where Members 2 and 3 should add their own
  cross-cutting models/widgets — don't duplicate `ApiClient`, `TokenStorage`,
  or the common widgets.
- All user-facing strings go through `AppLocalizations` — don't hard-code
  English strings in new screens.
- `ApiConfig.baseUrl` is the single place the backend URL is configured.
