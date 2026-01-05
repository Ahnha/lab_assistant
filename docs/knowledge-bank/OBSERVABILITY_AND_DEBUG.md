# Observability and Debug

## Logging

### Logging Utility
**File:** `lib/app/log.dart`

**Pattern:** Debug-only logging (no logging in release builds)

```dart
Log.d(String tag, String message)
```

**Implementation:**
- Uses `debugPrint()` (Flutter's debug print)
- Only logs when `kDebugMode == true`
- Format: `[LabAssistant/<tag>] <message>`

**Usage Examples:**
- `lib/data/lab_run_repository.dart:27` - "Saving run: {id}"
- `lib/features/run/run_controller.dart:588` - "Save triggered for run: {id}"
- `lib/features/inbox/inbox_screen.dart:216` - "Deleting run: {id}"

### Log Tags
Common tags used throughout the app:
- `Repository` - Repository operations
- `TemplateRepository` - Template operations
- `RunController` - Run state management
- `StorageInit` - Storage initialization
- `InboxScreen` - Inbox screen operations
- `TemplateToRunConverter` - Template conversion

### Log Levels
**Only one level:** Debug (`Log.d()`)

**No other levels found:**
- No error logging
- No warning logging
- No info logging

### Log Output
- **Debug mode:** Console output via `debugPrint()`
- **Release mode:** No output (disabled for performance)

## Metrics & Tracing

### Application Metrics
**None** - No metrics collection found.

### Performance Monitoring
**None** - No performance monitoring or APM integration.

### Error Tracking
**None** - No error tracking service (Sentry, Crashlytics, etc.).

## Where to Look for Logs

### Development
- **Console:** Flutter debug console (IDE or `flutter run` terminal)
- **Format:** `[LabAssistant/<tag>] <message>`

### Production
- **No logs** - Logging is disabled in release builds

### Platform-Specific Logs

#### Android
- **Debug:** `adb logcat` (filter for "LabAssistant")
- **Release:** No logs

#### iOS
- **Debug:** Xcode console
- **Release:** No logs

#### Web
- **Debug:** Browser console (F12)
- **Release:** No logs

## Debugging

### Debug Mode
- **Enabled by default** in development (`flutter run`)
- **Disabled** in release builds (`flutter build`)

### Debug Entrypoints

#### 1. RunController
**File:** `lib/features/run/run_controller.dart`

**Key debug points:**
- `_saveImmediately()` - Save operations
- `_debouncedSave()` - Debounce logic
- `_restoreTimers()` - Timer restoration on app restart
- `_checkAllSectionsForCompletion()` - Auto-completion logic

**State to inspect:**
- `_run` - Current run instance
- `_isSaving` - Save in progress flag
- `_activeTimers` - Active timer map
- `_activeIngredientSectionId` - Ingredient navigation context

#### 2. Storage Operations
**Files:**
- `lib/data/lab_run_store.dart` - Lab run storage
- `lib/data/recipe_template_store.dart` - Template storage
- `lib/data/storage_init.dart` - Storage initialization

**Key debug points:**
- `loadAllRuns()` - Load operations
- `saveRun()` - Save operations
- `StorageInit.initialize()` - Startup initialization

#### 3. Repository Layer
**Files:**
- `lib/data/lab_run_repository.dart`
- `lib/data/recipe_template_repository.dart`

**Key debug points:**
- `save()` - Repository save operations
- `loadActiveRuns()` - Active run loading
- `loadArchivedRuns()` - Archived run loading

#### 4. Domain Logic
**Files:**
- `lib/domain/lab_run_scaler.dart` - Formula scaling
- `lib/domain/template_to_run_converter.dart` - Template conversion
- `lib/domain/lab_run_validator.dart` - Validation (if implemented)

**Key debug points:**
- Scaling calculations
- Template-to-run conversion
- Validation rules

### Recommended Debug Workflow

#### 1. Check Logs
```bash
# Run app in debug mode
flutter run

# Watch for Log.d() output in console
```

#### 2. Inspect State
- Use Flutter DevTools widget inspector
- Set breakpoints in controllers/repositories
- Inspect `LabRun` instances in debugger

#### 3. Verify Storage
- Check SharedPreferences values (platform-specific)
- Verify JSON serialization/deserialization
- Check data version

#### 4. Test Domain Logic
- Unit tests in `test/domain/`
- Run: `flutter test test/domain/lab_run_scaler_test.dart`

## Common Debug Scenarios

### 1. Run Not Saving
**Check:**
- `RunController._isSaving` flag
- Debounce timer (800ms delay)
- Storage errors in logs
- SharedPreferences permissions

**Debug points:**
- `lib/features/run/run_controller.dart:583` - `_saveImmediately()`
- `lib/data/lab_run_store.dart:24` - `saveRun()`

### 2. Timer Not Restoring
**Check:**
- `RunController._restoreTimers()` on app start
- Timer state in `ProcedureStep` (timerState, remainingSeconds, timerStartedAt)
- App restart timing (if app was killed, timers may not restore)

**Debug points:**
- `lib/features/run/run_controller.dart:57` - `_restoreTimers()`

### 3. Storage Not Initializing
**Check:**
- `StorageInit.initialize()` on app start
- Data version mismatch
- Template seeding

**Debug points:**
- `lib/data/storage_init.dart:14` - `initialize()`
- `lib/main.dart:12` - Storage initialization call

### 4. Formula Scaling Issues
**Check:**
- Scaling calculations in `lab_run_scaler.dart`
- Percentage values in formula
- Rounding precision (2 decimal places)

**Debug points:**
- `lib/domain/lab_run_scaler.dart` - Scaling functions
- `lib/domain/formula.dart:140` - `scaleToBatchSize()`

### 5. Ingredient Auto-Completion Not Working
**Check:**
- `RunController._checkAllSectionsForCompletion()`
- Ingredient check state (`ingredientChecks` map)
- Section key format (`phase:<phaseId>:<itemId>` or `soap:oils:<oilId>`)
- Auto-return setting (`auto_return_enabled`)

**Debug points:**
- `lib/features/run/run_controller.dart:244` - `_checkAllSectionsForCompletion()`
- `lib/features/run/run_controller.dart:213` - `toggleIngredientCheck()`

## Debugging Tools

### Flutter DevTools
- **Widget Inspector:** Inspect widget tree
- **Performance:** Profile app performance
- **Memory:** Check memory usage
- **Network:** Not applicable (no network calls)

### IDE Debugger
- Set breakpoints in Dart code
- Inspect variables
- Step through code

### Platform-Specific Tools

#### Android
- **adb logcat:** View system logs
- **Android Studio:** Debugger, profiler

#### iOS
- **Xcode:** Debugger, Instruments
- **Console.app:** System logs

#### Web
- **Browser DevTools:** Console, Network, Performance
- **Flutter DevTools:** Web-specific debugging

## Troubleshooting Guide

### Issue: App Crashes on Startup
1. Check `StorageInit.initialize()` logs
2. Verify SharedPreferences permissions
3. Check data version mismatch
4. Verify template seeding

### Issue: Runs Not Loading
1. Check `LabRunStore.loadAllRuns()` logs
2. Verify JSON parsing (catch blocks return empty list on error)
3. Check SharedPreferences key: `lab_runs_v1`

### Issue: Timer Not Working
1. Check `RunController` timer state
2. Verify timer restoration on app restart
3. Check timer tick logic (1 second intervals)
4. Verify save on timer finish (not on every tick)

### Issue: Formula Not Scaling
1. Check percentage values in formula
2. Verify scaling calculations in `lab_run_scaler.dart`
3. Check rounding precision (2 decimals)

### Issue: Auto-Return Not Working
1. Check `auto_return_enabled` setting
2. Verify `_checkAllSectionsForCompletion()` logic
3. Check ingredient check state map
4. Verify section key format

## Performance Debugging

### Debounced Saves
- **Delay:** 800ms
- **Purpose:** Prevent excessive I/O
- **Debug:** Check `_saveDebounceTimer` in `RunController`

### Timer Performance
- **Update frequency:** 1 second
- **Save frequency:** Only on start/pause/finish (not on every tick)
- **Debug:** Check `_activeTimers` map size

### List Rendering
- Uses `ListView.builder` for efficient scrolling
- **Debug:** Check item count, scroll performance

## Error Handling

### Storage Errors
- **Pattern:** Try-catch in stores, return empty list on error
- **Files:** `lab_run_store.dart`, `recipe_template_store.dart`

### JSON Parsing Errors
- **Pattern:** Catch exceptions, return empty list or null
- **Files:** Domain model `fromJson()` methods

### User-Facing Errors
- **Pattern:** SnackBars with error messages
- **Examples:** Export failures, delete confirmations

## Best Practices

### Adding New Logs
1. Use `Log.d(tag, message)` format
2. Include relevant context (IDs, values)
3. Only log in debug mode (already handled by `Log.d()`)

### Debugging State Issues
1. Check `RunController` state first
2. Verify repository/store operations
3. Inspect domain model instances
4. Check SharedPreferences values

### Performance Debugging
1. Use Flutter DevTools profiler
2. Check debounce delays
3. Verify list rendering efficiency
4. Monitor timer update frequency
