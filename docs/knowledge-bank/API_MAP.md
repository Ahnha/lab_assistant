# API Map

## Overview

**Lab Assistant has no backend API.** The application is fully client-side and offline. All data is stored locally using SharedPreferences (platform-specific key-value storage).

## No REST Endpoints

There are no REST endpoints, GraphQL APIs, or any other external API integrations.

## No Network Calls

The app does not make any HTTP requests or network calls. All functionality is local:
- Data storage: SharedPreferences (local)
- Data operations: In-memory operations on local data
- No authentication: Not applicable (local-only app)
- No authorization: Not applicable (single-user device)

## Data Access Pattern

Instead of API endpoints, the app uses a **repository pattern** for data access:

### LabRunRepository
**File:** `lib/data/lab_run_repository.dart`

**Methods:**
- `loadActiveRuns()` → `Future<List<LabRun>>`
- `loadArchivedRuns()` → `Future<List<LabRun>>`
- `save(LabRun run)` → `Future<void>`
- `delete(String id)` → `Future<void>`
- `archive(String id)` → `Future<void>`

### RecipeTemplateRepository
**File:** `lib/data/recipe_template_repository.dart`

**Methods:**
- `loadAllTemplates()` → `Future<List<RecipeTemplate>>`
- `loadUserTemplates()` → `Future<List<RecipeTemplate>>`
- `loadSystemTemplates()` → `Future<List<RecipeTemplate>>`
- `save(RecipeTemplate template)` → `Future<void>`
- `delete(String id)` → `Future<void>`
- `getById(String id)` → `Future<RecipeTemplate?>`
- `ensureExists(RecipeTemplate template)` → `Future<bool>`

## Error Handling

Since there are no API calls, there is no HTTP error handling. Error handling is limited to:
- **Storage errors:** Caught in stores, return empty lists or null
- **JSON parsing errors:** Caught in domain model `fromJson()` methods
- **User-facing errors:** Shown via SnackBars

## Future Considerations

If a backend API is added in the future, this document should be updated with:
- Base URL
- Authentication mechanism
- Endpoint list with methods, paths, request/response DTOs
- Error response format
- Rate limiting (if any)

## Related Documentation

- **Data Model:** See [DATA_MODEL.md](./DATA_MODEL.md) for storage schema
- **Architecture:** See [ARCHITECTURE.md](./ARCHITECTURE.md) for repository pattern details
- **Build & Run:** See [BUILD_AND_RUN.md](./BUILD_AND_RUN.md) for local development
