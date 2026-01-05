# Frontend Map

## Overview

Lab Assistant is a **Flutter application** with a Material Design UI. The app uses a **feature-based architecture** with clear separation between presentation, controllers, and data layers.

## Routing Structure

### Navigation Pattern
- **Root:** `MainScreen` with bottom navigation bar
- **Navigation:** Material navigation (Navigator.push/pop)
- **Responsive:** Master/detail layout for tablets (≥900dp width), regular navigation for phones

### Routes

#### Main Screen
**File:** `lib/app/main_screen.dart`

Bottom navigation with 3 tabs:
1. **Inbox** (index 0)
   - Active (non-archived) runs
   - Responsive: `InboxMasterDetailScreen` (tablet) or `InboxScreen` (phone)
2. **History** (index 1)
   - Archived runs
   - File: `lib/features/run/history_screen.dart`
3. **Settings** (index 2)
   - App settings
   - File: `lib/features/settings/settings_screen.dart`

#### Inbox Flow
```
MainScreen (Inbox tab)
  └─> InboxScreen (phone) / InboxMasterDetailScreen (tablet)
       └─> RunDetailScreen (on tap)
```

**Files:**
- `lib/features/inbox/inbox_screen.dart` - Phone layout
- `lib/features/inbox/inbox_master_detail_screen.dart` - Tablet layout
- `lib/features/run/run_detail_screen.dart` - Run execution screen

#### Templates Flow
**Note:** Templates screen is not directly accessible from main navigation (may be accessed from settings or other entry points).

**File:** `lib/features/templates/templates_screen.dart`

## Pages & Screens

### InboxScreen
**File:** `lib/features/inbox/inbox_screen.dart`

**Purpose:** List of active (non-archived) lab runs

**Features:**
- Pull-to-refresh
- Swipe-to-delete (with undo)
- Tap to open run detail
- Empty state when no runs
- Progress indicator (completed/total steps)

**Actions:**
- Delete run (swipe left)
- Open run (tap)
- Export run (copy JSON to clipboard) - *Note: Export functionality exists but UI button not visible in current code*

### InboxMasterDetailScreen
**File:** `lib/features/inbox/inbox_master_detail_screen.dart`

**Purpose:** Tablet master/detail layout for inbox

**Layout:**
- Left: List of runs
- Right: Selected run detail (or empty state)

### RunDetailScreen
**File:** `lib/features/run/run_detail_screen.dart`

**Purpose:** Main run execution screen

**Layout:**
- Tab bar: "Steps" and "Ingredients"
- Steps tab: Scrollable list of procedure steps
- Ingredients tab: Formula view (soap oils or cream phases)

**Features:**
- Step status management (todo/doing/done/skipped)
- Checklist item toggles
- Timer controls (start/pause/reset/skip)
- Numeric input for inputNumber steps
- Note-taking for note steps
- Ingredient checkboxes
- Formula scaling (soap oils or cream batch size)
- Auto-return to steps when ingredient section completes (if enabled)
- Reset progress
- Finish run (archives run)

**State Management:**
- Uses `RunController` (ChangeNotifier) for run state
- Listens to controller changes for UI updates

### HistoryScreen
**File:** `lib/features/run/history_screen.dart`

**Purpose:** List of archived (finished) runs

**Features:**
- Similar to InboxScreen but shows archived runs
- Tap to view archived run (read-only or editable?)

### SettingsScreen
**File:** `lib/features/settings/settings_screen.dart`

**Purpose:** App settings

**Settings:**
- Lab Mode toggle (enables 1.15x text scale)
- Auto-return toggle (auto-return to steps when ingredient section completes)
- Import run (from clipboard JSON)

**Components:**
- `lib/features/settings/components/settings_section.dart`
- `lib/features/settings/components/settings_toggle_row.dart`
- `lib/features/settings/components/import_run_card.dart`

### TemplatesScreen
**File:** `lib/features/templates/templates_screen.dart`

**Purpose:** List of recipe templates

**Features:**
- View all templates (system + user)
- Create run from template
- Edit/delete templates (if implemented)

## State Management

### Pattern
**ChangeNotifier** pattern (Flutter built-in, no external state management library)

### RunController
**File:** `lib/features/run/run_controller.dart`

**Purpose:** Manages state for a single lab run

**Responsibilities:**
- Owns `LabRun` instance
- Handles all mutations (checklist toggles, input values, status changes)
- Debounced saves (800ms delay) to avoid excessive I/O
- Timer management (restores running timers on app restart)
- Ingredient check state management
- Auto-completion of steps when ingredient sections complete

**Key Methods:**
- `toggleChecklistItem(stepId, itemId)` - Toggle checklist item
- `setStepStatus(stepId, status)` - Update step status
- `setInputNumber(stepId, value)` - Set numeric input value
- `setRunNotes(notes)` - Update run notes
- `startTimer(stepId)` - Start timer
- `pauseTimer(stepId)` - Pause timer
- `resetTimer(stepId)` - Reset timer
- `toggleIngredientCheck(key)` - Toggle ingredient checkbox
- `finishRun()` - Archive run

**Listeners:**
- Widgets listen via `addListener()` and rebuild on `notifyListeners()`

### Screen-Level State
Most screens use `StatefulWidget` with local state for:
- Loading states
- List data (loaded from repositories)
- UI state (selected tab, expanded items, etc.)

## Data Fetching

### Pattern
**Repository pattern** - Screens call repositories, which call stores

### Flow
```
Screen → Repository → Store → SharedPreferences
```

### Examples

#### Loading Active Runs
```dart
// In InboxScreen
final repository = LabRunRepository();
final runs = await repository.loadActiveRuns();
```

#### Saving Run
```dart
// In RunController
await _repository.save(_run);
```

### Caching
**None** - Data is loaded from SharedPreferences on demand. No in-memory cache.

## API Client

**Not applicable** - No backend API. All data is local (SharedPreferences).

## UI Component Library

### Design System
**Material Design 3** (Flutter's Material library)

### Theme
**File:** `lib/app/app_theme.dart`

- Light theme only (no dark theme found)
- Custom color scheme
- Typography configuration

### Design Tokens
**File:** `lib/app/ui_tokens.dart`

**Spacing:**
- `spacingS`, `spacingM`, `spacingL`, `spacingXL`

**Border Radius:**
- `borderRadiusM`, etc.

### Reusable Components

#### App-Level Widgets
**Location:** `lib/app/widgets/`

- **`app_card.dart`** - Card widget
- **`primary_button.dart`** - Primary action button
- **`secondary_button.dart`** - Secondary action button
- **`section_header.dart`** - Section header widget

#### Feature Widgets
**Location:** `lib/features/run/widgets/`

- **`instruction_step_widget.dart`** - Instruction step card
- **`checklist_step_widget.dart`** - Checklist step card
- **`timer_step_widget.dart`** - Timer step card
- **`input_number_step_widget.dart`** - Numeric input step card
- **`note_step_widget.dart`** - Note-taking step card
- **`section_step_widget.dart`** - Section header step widget
- **`ingredients_view.dart`** - Ingredients tab view (formula display)

#### Shared Widgets
**Location:** `lib/widgets/`

- **`recipe_badge.dart`** - Badge showing recipe kind (SOAP/CREAM)

## Component Organization

### Structure
```
lib/
  app/
    widgets/          # App-level reusable components
  features/
    <feature>/
      widgets/       # Feature-specific components
  widgets/           # Shared widgets (cross-feature)
```

### Patterns
- **Feature-based:** Components are organized by feature
- **Reusability:** App-level widgets are shared across features
- **Encapsulation:** Feature widgets are scoped to their feature

## Responsive Design

### Breakpoints
- **Tablet:** ≥900dp width
- **Phone:** <900dp width

### Adaptive Layouts
- **Inbox:** Master/detail for tablets, regular list for phones
- **Run Detail:** Same layout for all screen sizes (scrollable)

### Lab Mode
**File:** `lib/data/app_settings.dart`

When enabled:
- Text scale factor: 1.15x (applied globally via `MediaQuery`)
- Larger spacing in UI components
- **Purpose:** Accessibility for lab environment (gloves, distance from screen)

## Navigation Patterns

### Stack Navigation
- Uses Flutter's `Navigator` (Material navigation)
- Push/pop pattern for detail screens

### Deep Linking
**Not implemented** - No deep linking or URL routing found.

### Back Navigation
- Standard Android/iOS back button behavior
- App bar back button in detail screens

## Error Handling

### Pattern
- Try-catch in async operations
- SnackBars for user feedback
- Empty states for missing data

### Examples
- **Storage errors:** Caught in stores, return empty lists
- **Export errors:** Shown via SnackBar with error message
- **Delete confirmation:** Dialog before deletion

## Accessibility

### Lab Mode
- **Purpose:** Larger text and spacing for lab environment
- **Implementation:** Global text scale factor (1.15x) when enabled

### Other Accessibility Features
- **Material Design:** Built-in accessibility support (semantics, etc.)
- **No custom accessibility features found** beyond Lab Mode

## Performance Considerations

### Debounced Saves
- **Delay:** 800ms after last user action
- **Purpose:** Avoid excessive I/O during rapid interactions
- **Implementation:** `RunController._debouncedSave()`

### List Rendering
- Uses `ListView.builder` for efficient scrolling (lazy loading)

### Timer Updates
- Timer ticks update UI only (no save on every tick)
- Save only on timer start/pause/finish

## Platform-Specific UI

### Web
- Same UI as mobile (responsive design)
- No platform-specific UI differences found

### Mobile (Android/iOS)
- Material Design (consistent across platforms)
- Platform-specific navigation (Android back button, iOS swipe gestures) handled by Flutter

## UI State Management Details

### RunController State
- **Run instance:** Owned by controller
- **Saving state:** `_isSaving` flag (prevents duplicate saves)
- **Active timers:** Map of timer IDs to Timer objects
- **Ingredient context:** `_activeIngredientSectionId`, `_sourceStepId` for navigation

### Screen State
- **Loading:** `_isLoading` boolean
- **Data:** Lists loaded from repositories
- **UI state:** Selected tabs, expanded items, etc.

## Form Handling

### Input Types
1. **Numeric Input** (`inputNumber` steps)
   - Formatter: `DecimalInputFormatter` (`lib/utils/decimal_input_formatter.dart`)
   - Unit display (e.g., "°C", "pH")

2. **Text Input** (`note` steps)
   - Multi-line text input
   - Stored in step description

3. **Checkbox** (checklist items, ingredient checks)
   - Toggle state

### Validation
- **No client-side validation found** (domain validation may exist in `lab_run_validator.dart`)

## Animation & Transitions

### Standard Material Transitions
- Page transitions: Material page route transitions
- No custom animations found

### Timer UI Updates
- Timer countdown updates every second (smooth via `notifyListeners()`)
