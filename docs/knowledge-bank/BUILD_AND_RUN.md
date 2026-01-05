# Build and Run

## Prerequisites

### Required Versions
- **Flutter SDK:** `^3.10.4` (see `pubspec.yaml` line 7)
- **Dart SDK:** Included with Flutter
- **Platform Support:**
  - Android (via `android/` folder)
  - iOS (via `ios/` folder)
  - Web (via `web/` folder)
  - Linux (via `linux/` folder)
  - macOS (via `macos/` folder)
  - Windows (via `windows/` folder)

### Dependencies
- **`shared_preferences: ^2.2.2`** - Local storage
- **`flutter_lints: ^6.0.0`** - Linting rules (dev dependency)

## Installation

### 1. Install Flutter
Follow [Flutter installation guide](https://docs.flutter.dev/get-started/install) for your platform.

### 2. Verify Installation
```bash
flutter doctor
```

### 3. Get Dependencies
```bash
cd lab_assistant
flutter pub get
```

## Running Locally

### Web (Development)
```bash
flutter run -d chrome
```

**Note:** The app is configured for GitHub Pages deployment (see `README.md` in project root).

### Android (Development)
```bash
flutter run -d android
```

### iOS (Development)
```bash
flutter run -d ios
```

**Note:** Requires macOS and Xcode.

### Desktop (Development)
```bash
# Linux
flutter run -d linux

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

## Building for Production

### Web Build
```bash
flutter build web
```

**Output:** `build/web/`

**GitHub Pages:** The build includes base-href configuration for GitHub Pages deployment (see project `README.md`).

### Android Build
```bash
# APK
flutter build apk

# App Bundle (for Play Store)
flutter build appbundle
```

**Output:** 
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### iOS Build
```bash
flutter build ios
```

**Note:** Requires macOS, Xcode, and proper code signing setup.

### Desktop Builds
```bash
# Linux
flutter build linux

# macOS
flutter build macos

# Windows
flutter build windows
```

## Testing

### Run All Tests
```bash
flutter test
```

### Test Files
- **`test/widget_test.dart`** - Widget tests
- **`test/domain/lab_run_scaler_test.dart`** - Domain logic tests

### Run Specific Test File
```bash
flutter test test/domain/lab_run_scaler_test.dart
```

## Linting & Formatting

### Analyze Code
```bash
flutter analyze
```

**Configuration:** `analysis_options.yaml`

### Format Code
```bash
flutter format .
```

## Environment & Config

### Environment Variables
**None required** - The app is fully client-side with no external API dependencies.

### Configuration Files
- **`pubspec.yaml`** - Flutter package configuration
- **`analysis_options.yaml`** - Dart analyzer/linter configuration
- **`android/app/build.gradle.kts`** - Android build configuration
- **`ios/Runner.xcodeproj/`** - iOS project configuration

### App Settings (Runtime)
Settings are stored in SharedPreferences and can be changed in-app:
- **Lab Mode:** Enables larger text (1.15x scale)
  - **Storage Key:** `lab_mode_enabled`
  - **File:** `lib/data/app_settings.dart`
- **Auto-Return:** Auto-return to steps when ingredient section completes
  - **Storage Key:** `auto_return_enabled`
  - **Default:** `true`
  - **File:** `lib/data/app_settings.dart`

### Data Storage
- **Technology:** SharedPreferences (platform-specific storage)
- **Location:**
  - **Android:** `/data/data/<package>/shared_prefs/`
  - **iOS:** UserDefaults
  - **Web:** LocalStorage
  - **Desktop:** Platform-specific key-value store

### Storage Keys
- `lab_runs_v1` - JSON array of LabRun objects
- `recipe_templates_v1` - JSON array of RecipeTemplate objects
- `data_version` - Integer (currently `1`)
- `lab_mode_enabled` - Boolean
- `auto_return_enabled` - Boolean

## Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues
```bash
flutter doctor -v
```
Resolve any issues reported (missing Android SDK, Xcode, etc.).

#### 2. Dependency Issues
```bash
flutter clean
flutter pub get
```

#### 3. Build Failures
- **Android:** Check `android/app/build.gradle.kts` for version conflicts
- **iOS:** Ensure Xcode is properly configured and code signing is set up
- **Web:** Check browser console for errors

#### 4. Storage Not Initializing
- Check `lib/data/storage_init.dart` for initialization errors
- Verify SharedPreferences plugin is working: `flutter pub get`
- Check app logs (debug mode) for storage errors

#### 5. Timer Not Persisting
- Timers are restored on app restart if app was properly closed
- If app is killed by OS, timer state may be lost (expected behavior)
- Check `RunController._restoreTimers()` in `lib/features/run/run_controller.dart`

#### 6. Web Build Fails
- Ensure `web/index.html` exists
- Check for CORS issues if accessing external resources (none in this app)
- Verify base-href is correct for deployment target

### Debug Mode
- **Logging:** Enabled automatically in debug mode via `lib/app/log.dart`
- **Log Format:** `[LabAssistant/<tag>] <message>`
- **Release:** Logging is disabled in release builds (no performance impact)

### Platform-Specific Issues

#### Android
- **Min SDK:** Check `android/app/build.gradle.kts` for minimum SDK version
- **Permissions:** No special permissions required (SharedPreferences is built-in)

#### iOS
- **Deployment Target:** Check `ios/Podfile` and `ios/Runner.xcodeproj`
- **Code Signing:** Required for device testing and App Store builds

#### Web
- **Base URL:** Configured for GitHub Pages (see project `README.md`)
- **Browser Support:** Modern browsers (Chrome, Firefox, Safari, Edge)

## Development Workflow

### Typical Workflow
1. **Make changes** to Dart files in `lib/`
2. **Hot reload:** Press `r` in terminal or click hot reload in IDE
3. **Hot restart:** Press `R` in terminal or click hot restart in IDE
4. **Run tests:** `flutter test`
5. **Format code:** `flutter format .`
6. **Analyze:** `flutter analyze`

### Hot Reload vs Hot Restart
- **Hot Reload:** Preserves app state, fast (use for UI changes)
- **Hot Restart:** Resets app state, slower (use for logic changes or when hot reload fails)

### Debugging
- **IDE:** Use Flutter DevTools or IDE debugger
- **Logs:** Check console output (debug mode only)
- **Breakpoints:** Set in IDE debugger
- **Inspect Widgets:** Use Flutter DevTools widget inspector

## CI/CD

### GitHub Actions
**Status:** Not found in repository (no `.github/workflows/` directory)

**Note:** The project `README.md` mentions automatic GitHub Pages deployment, but no workflow file is present. This may be configured externally or needs to be added.

### Manual Deployment

#### GitHub Pages (Web)
1. Build web app: `flutter build web`
2. Deploy `build/web/` to `gh-pages` branch
3. Configure GitHub Pages to serve from `gh-pages` branch (root directory)

#### Android (Play Store)
1. Build app bundle: `flutter build appbundle`
2. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console

#### iOS (App Store)
1. Build iOS: `flutter build ios`
2. Archive in Xcode
3. Upload via Xcode Organizer or App Store Connect

## Version Information

- **App Version:** `0.1.0` (see `pubspec.yaml` line 4)
- **Data Version:** `1` (see `lib/data/data_version.dart`)
- **Flutter SDK:** `^3.10.4`
