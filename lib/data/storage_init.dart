import 'package:shared_preferences/shared_preferences.dart';
import 'data_version.dart';
import 'recipe_template_repository.dart';
import 'seed_data.dart';
import '../app/log.dart';

/// Handles storage initialization and version management.
/// On startup, checks data version and clears/re-seeds if needed.
class StorageInit {
  /// Initializes storage, ensuring data version is correct.
  /// - If version is missing: Preserves existing data and sets version (upgrade from pre-versioning)
  /// - If version != DATA_VERSION: Handles version mismatch (future migration logic)
  /// - Ensures system templates are seeded
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(DATA_VERSION_KEY);

    if (storedVersion == null) {
      // Upgrade from version without data versioning
      // Check if there's existing data to preserve
      final runsData = prefs.getString('lab_runs_v1');
      final hasExistingRuns = runsData != null && runsData.isNotEmpty;

      if (hasExistingRuns) {
        Log.d(
          'StorageInit',
          'Upgrading from pre-versioned storage. Preserving existing data.',
        );
        // Preserve existing data, just set the version
        await prefs.setInt(DATA_VERSION_KEY, DATA_VERSION);
        // Ensure templates are seeded (they might not exist)
        await _seedTemplates();
        Log.d(
          'StorageInit',
          'Storage upgraded to version $DATA_VERSION (data preserved)',
        );
      } else {
        // No existing data, safe to clear and seed
        Log.d(
          'StorageInit',
          'No existing data found. Initializing fresh storage.',
        );
        await _clearAllData(prefs);
        await _seedTemplates();
        await prefs.setInt(DATA_VERSION_KEY, DATA_VERSION);
        Log.d('StorageInit', 'Storage initialized with version $DATA_VERSION');
      }
    } else if (storedVersion != DATA_VERSION) {
      // Actual version mismatch (future migration case)
      Log.d(
        'StorageInit',
        'Data version mismatch: stored=$storedVersion, current=$DATA_VERSION. Preserving data for now.',
      );
      // For now, preserve data and update version
      // TODO: Implement proper migration logic when DATA_VERSION changes
      await prefs.setInt(DATA_VERSION_KEY, DATA_VERSION);
      // Ensure templates are seeded
      await _seedTemplates();
      Log.d(
        'StorageInit',
        'Storage version updated to $DATA_VERSION (data preserved)',
      );
    } else {
      // Version matches, just ensure templates exist
      await _seedTemplates();
      Log.d('StorageInit', 'Storage version $DATA_VERSION confirmed');
    }
  }

  /// Clears all stored runs and templates.
  static Future<void> _clearAllData(SharedPreferences prefs) async {
    // Clear runs
    await prefs.remove('lab_runs_v1');

    // Clear templates
    await prefs.remove('recipe_templates_v1');

    // Clear any other stored data
    await prefs.remove('data_migration_v1_completed');

    Log.d('StorageInit', 'All stored data cleared');
  }

  /// Seeds system templates.
  static Future<void> _seedTemplates() async {
    final templateRepo = RecipeTemplateRepository();

    final soapTemplate = SeedData.createSoapTemplate();
    final creamTemplate = SeedData.createCreamTemplate();

    await templateRepo.ensureExists(soapTemplate);
    await templateRepo.ensureExists(creamTemplate);

    Log.d('StorageInit', 'System templates seeded');
  }
}
