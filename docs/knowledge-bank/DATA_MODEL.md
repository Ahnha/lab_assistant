# Data Model

## Overview

Lab Assistant uses **local storage only** (SharedPreferences) with JSON serialization. There is no database—all data is stored as JSON strings in platform key-value stores.

## Storage Technology

- **Library:** `shared_preferences` (Flutter plugin)
- **Format:** JSON strings stored in SharedPreferences
- **Platform Storage:**
  - **Android:** `/data/data/<package>/shared_prefs/`
  - **iOS:** UserDefaults
  - **Web:** LocalStorage
  - **Desktop:** Platform-specific key-value store

## Storage Keys

| Key | Type | Description | File Reference |
|-----|------|-------------|----------------|
| `lab_runs_v1` | String (JSON) | Array of LabRun objects | `lib/data/lab_run_store.dart:6` |
| `recipe_templates_v1` | String (JSON) | Array of RecipeTemplate objects | `lib/data/recipe_template_store.dart:6` |
| `data_version` | Int | Data schema version | `lib/data/data_version.dart:3` |
| `lab_mode_enabled` | Bool | Lab Mode setting | `lib/data/app_settings.dart:4` |
| `auto_return_enabled` | Bool | Auto-return setting | `lib/data/app_settings.dart:5` |

## Domain Models

### LabRun
**File:** `lib/domain/lab_run.dart`

Core entity representing a lab run (execution of a recipe).

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (format: `run_<timestamp>_<kind>`) |
| `createdAt` | DateTime | When the run was created |
| `recipe` | RecipeRef | Reference to the recipe (name, kind, default batch size) |
| `batchCode` | String? | Optional batch code (format: `SOAP-YYYYMMDD` or `CREAM-YYYYMMDD`) |
| `steps` | List<ProcedureStep> | Ordered list of procedure steps |
| `notes` | String? | Optional run notes |
| `archived` | Bool | Whether run is archived (default: `false`) |
| `finishedAt` | DateTime? | When run was finished (set when archived) |
| `formula` | Formula? | Optional formula (soap or cream style) |
| `templateId` | String? | ID of template this run was created from |
| `ingredientChecks` | Map<String, bool> | Ingredient check states (key format: `phase:<phaseId>:<itemId>` or `soap:oils:<oilId>`) |

#### Computed Properties
- `completedSteps` - Count of completed steps (excludes section steps)
- `totalSteps` - Total count of steps (excludes section steps)

#### JSON Serialization
- **To JSON:** `toJson()` method
- **From JSON:** `LabRun.fromJson(Map<String, dynamic>)`

### RecipeTemplate
**File:** `lib/domain/recipe_template.dart`

Template for creating lab runs. Can be system (built-in) or user-created.

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `name` | String | Template name |
| `kind` | RecipeKind | Recipe type (`soap` or `cream`) |
| `createdAt` | DateTime | Creation timestamp |
| `updatedAt` | DateTime | Last update timestamp |
| `formula` | Formula? | Optional formula |
| `steps` | List<ProcedureStep> | Ordered list of procedure steps |
| `isSystem` | Bool | Whether this is a system template (default: `false`) |

#### Methods
- `copyWith(...)` - Creates a copy with updated fields (auto-updates `updatedAt`)

#### JSON Serialization
- **To JSON:** `toJson()` method
- **From JSON:** `RecipeTemplate.fromJson(Map<String, dynamic>)`

### Formula
**File:** `lib/domain/formula.dart`

Unified formula model supporting both soap-style and cream-style formulas.

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `batchSizeGrams` | double? | Total batch size in grams |
| `phases` | List<FormulaPhase>? | Cream-style phases (Phase A, B, C, etc.) |
| `oilsTotalGrams` | double? | Soap-style total oils weight |
| `oils` | List<SoapOil>? | Soap-style oils list |
| `lye` | SoapLye? | Soap-style lye |
| `water` | SoapWater? | Soap-style water |
| `superfatPercent` | double? | Soap-style superfat percentage |

#### Type Detection
- `isCreamStyle` - Returns `true` if `phases != null && phases.isNotEmpty`
- `isSoapStyle` - Returns `true` if `oils != null && oils.isNotEmpty`

#### Methods
- `scaleToBatchSize(double)` - Scales formula to new batch size (2 decimal precision)

#### JSON Serialization
- **To JSON:** `toJson()` method
- **From JSON:** `Formula.fromJson(Map<String, dynamic>)`

### FormulaPhase
**File:** `lib/domain/formula_phase.dart`

Represents a phase in a cream-style formula (e.g., Phase A: Water Phase).

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Phase identifier (e.g., `pA`, `pB`, `pC`) |
| `name` | String | Phase name (e.g., "Water Phase") |
| `order` | int | Phase order (1, 2, 3, ...) |
| `totalGrams` | double? | Total grams in phase (optional) |
| `items` | List<FormulaItem> | List of ingredients in this phase |

### FormulaItem
**File:** `lib/domain/formula_item.dart`

Individual ingredient/item in a formula phase.

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Item identifier |
| `name` | String | Ingredient name |
| `grams` | double | Weight in grams |
| `percent` | double? | Percentage of total batch (optional) |
| `notes` | String? | Optional notes |

### SoapOil, SoapLye, SoapWater
**File:** `lib/domain/soap_formula.dart`

Soap-specific formula components.

#### SoapOil
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Oil identifier |
| `name` | String | Oil name |
| `grams` | double | Weight in grams |
| `percent` | double? | Percentage of oils total (optional) |

#### SoapLye
| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Lye name (e.g., "Sodium Hydroxide") |
| `grams` | double | Weight in grams |

#### SoapWater
| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Water name (e.g., "Distilled Water") |
| `grams` | double | Weight in grams |

### ProcedureStep
**File:** `lib/domain/procedure_step.dart`

A step in a lab run procedure.

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Step identifier |
| `kind` | StepKind | Step type (see StepKind enum) |
| `title` | String | Step title |
| `description` | String? | Optional description |
| `order` | int | Step order (1, 2, 3, ...) |
| `status` | StepStatus | Current status (see StepStatus enum) |
| `items` | List<ChecklistItem>? | Checklist items (for `checklist` kind) |
| `timerSeconds` | int? | Initial timer duration (for `timer` kind) |
| `remainingSeconds` | int? | Current remaining time (for `timer` kind) |
| `timerState` | TimerState? | Timer state: `idle`, `running`, `paused`, `finished` |
| `timerStartedAt` | DateTime? | When timer was started |
| `unit` | String? | Unit for input (for `inputNumber` kind, e.g., "°C", "pH") |
| `value` | num? | Numeric input value (for `inputNumber` kind) |
| `ingredientSectionId` | String? | Linked ingredient section ID (e.g., `phase:pA`, `soap:oils`) |
| `ingredientSectionLabel` | String? | Display label for ingredient section |

#### StepKind Enum
**File:** `lib/domain/step_kind.dart`
- `instruction` - Instruction step
- `checklist` - Checklist step
- `timer` - Timer step
- `inputNumber` - Numeric input step
- `note` - Note-taking step
- `section` - Section header (non-interactive)

#### StepStatus Enum
**File:** `lib/domain/step_status.dart`
- `todo` - Not started
- `doing` - In progress
- `done` - Completed
- `skipped` - Skipped

### ChecklistItem
**File:** `lib/domain/checklist_item.dart`

Item in a checklist step.

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Item identifier |
| `label` | String | Item label |
| `done` | Bool | Whether item is checked (default: `false`) |

### RecipeRef
**File:** `lib/domain/recipe_ref.dart`

Reference to a recipe (used in LabRun to avoid duplicating full template).

#### Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Recipe/template ID |
| `kind` | RecipeKind | Recipe type |
| `name` | String | Recipe name |
| `defaultBatchSizeGrams` | int? | Default batch size |

### RecipeKind Enum
**File:** `lib/domain/recipe_kind.dart`
- `soap` - Soap recipe
- `cream` - Cream/cosmetic recipe

## Data Relationships

```
RecipeTemplate (1) ──→ (many) LabRun
  - LabRun.templateId references RecipeTemplate.id
  - LabRun.recipe is a RecipeRef (denormalized copy)

LabRun (1) ──→ (many) ProcedureStep
  - Steps are ordered by `order` field

RecipeTemplate (1) ──→ (many) ProcedureStep
  - Steps are ordered by `order` field

LabRun (1) ──→ (0..1) Formula
RecipeTemplate (1) ──→ (0..1) Formula

Formula (1) ──→ (many) FormulaPhase (cream-style)
FormulaPhase (1) ──→ (many) FormulaItem

Formula (1) ──→ (many) SoapOil (soap-style)
Formula (1) ──→ (0..1) SoapLye (soap-style)
Formula (1) ──→ (0..1) SoapWater (soap-style)

ProcedureStep (1) ──→ (many) ChecklistItem (if kind == checklist)
```

## Storage Schema

### Lab Runs Storage
**Key:** `lab_runs_v1`  
**Type:** String (JSON array)

```json
[
  {
    "id": "run_1234567890_soap",
    "createdAt": "2025-01-05T12:00:00.000Z",
    "recipe": {
      "id": "template-soap-001",
      "kind": "soap",
      "name": "Basic Cold Process Soap",
      "defaultBatchSizeGrams": 1000
    },
    "batchCode": "SOAP-20250105",
    "steps": [...],
    "notes": null,
    "archived": false,
    "finishedAt": null,
    "formula": {...},
    "templateId": "template-soap-001",
    "ingredientChecks": {}
  }
]
```

### Recipe Templates Storage
**Key:** `recipe_templates_v1`  
**Type:** String (JSON array)

```json
[
  {
    "id": "template-soap-001",
    "name": "Basic Cold Process Soap",
    "kind": "soap",
    "createdAt": "2025-01-05T12:00:00.000Z",
    "updatedAt": "2025-01-05T12:00:00.000Z",
    "formula": {...},
    "steps": [...],
    "isSystem": true
  }
]
```

## Data Versioning

### Current Version
- **Version:** `1`
- **File:** `lib/data/data_version.dart`

### Version Management
**File:** `lib/data/storage_init.dart`

On app startup:
1. Check stored `data_version` in SharedPreferences
2. If missing: Preserve existing data (if any), set version to `1`, seed templates
3. If version mismatch: Preserve data, update version (migration TODO)
4. If version matches: Ensure system templates exist

**Note:** Migration logic is not yet implemented (TODO in code).

## Data Invariants

### Constraints
1. **LabRun ID uniqueness:** Enforced by storage (overwrites on save if ID exists)
2. **RecipeTemplate ID uniqueness:** Enforced by storage (overwrites on save if ID exists)
3. **Step order:** Steps are ordered by `order` field (not enforced by storage, but assumed by UI)
4. **Timer state:** `remainingSeconds` must be ≤ `timerSeconds` (not enforced, but logic assumes)

### Unique Keys
- **LabRun:** `id` (generated as `run_<timestamp>_<kind>`)
- **RecipeTemplate:** `id` (user-defined or system-generated)

### Indexes
**None** - Data is stored as JSON arrays, so lookups are O(n). For small datasets (typical use case), this is acceptable.

## Seed Data

**File:** `lib/data/seed_data.dart`

System templates are seeded on first run:
1. **Soap Template:** `template-soap-001` - "Basic Cold Process Soap"
2. **Cream Template:** `template-cream-001` - "Moisturizing Face Cream"

These templates are marked with `isSystem: true` and are never shown as runs.

## Data Migration

### Current Status
- **Migration Logic:** Not implemented (TODO in `lib/data/storage_init.dart:55`)
- **Current Behavior:** On version mismatch, data is preserved and version is updated

### Future Migration
When `DATA_VERSION` changes:
1. Check stored version
2. Run migration logic (to be implemented)
3. Update version
4. Ensure templates are seeded

## Repository Pattern

### LabRunRepository
**File:** `lib/data/lab_run_repository.dart`

Methods:
- `loadActiveRuns()` - Returns non-archived runs
- `loadArchivedRuns()` - Returns archived runs
- `save(LabRun)` - Creates or updates run
- `delete(String id)` - Deletes run permanently
- `archive(String id)` - Marks run as archived

### RecipeTemplateRepository
**File:** `lib/data/recipe_template_repository.dart`

Methods:
- `loadAllTemplates()` - Returns all templates
- `loadUserTemplates()` - Returns non-system templates
- `loadSystemTemplates()` - Returns system templates
- `save(RecipeTemplate)` - Creates or updates template
- `delete(String id)` - Deletes template
- `getById(String id)` - Gets template by ID
- `ensureExists(RecipeTemplate)` - Creates template if it doesn't exist

## Storage Implementation

### LabRunStore
**File:** `lib/data/lab_run_store.dart`

Low-level storage operations:
- `loadAllRuns()` - Loads all runs from SharedPreferences
- `saveRun(LabRun)` - Saves/updates run in array
- `archiveRun(String id)` - Marks run as archived
- `deleteRun(String id)` - Removes run from array

### RecipeTemplateStore
**File:** `lib/data/recipe_template_store.dart`

Low-level storage operations:
- `loadAllTemplates()` - Loads all templates from SharedPreferences
- `saveTemplate(RecipeTemplate)` - Saves/updates template in array
- `deleteTemplate(String id)` - Removes template from array
- `getTemplateById(String id)` - Gets template by ID
- `ensureTemplateExists(RecipeTemplate)` - Creates if missing
