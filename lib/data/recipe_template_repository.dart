import '../domain/recipe_template.dart';
import 'recipe_template_store.dart';
import '../app/log.dart';

/// Repository layer wrapping RecipeTemplateStore.
///
/// Provides a clean interface for widgets to interact with template data.
class RecipeTemplateRepository {
  final RecipeTemplateStore _store = RecipeTemplateStore();

  /// Load all templates.
  Future<List<RecipeTemplate>> loadAllTemplates() async {
    return await _store.loadAllTemplates();
  }

  /// Load only user-created templates (non-system).
  Future<List<RecipeTemplate>> loadUserTemplates() async {
    final all = await loadAllTemplates();
    return all.where((t) => !t.isSystem).toList();
  }

  /// Load only system templates.
  Future<List<RecipeTemplate>> loadSystemTemplates() async {
    final all = await loadAllTemplates();
    return all.where((t) => t.isSystem).toList();
  }

  /// Save a template. Creates new or updates existing.
  Future<void> save(RecipeTemplate template) async {
    Log.d('TemplateRepository', 'Saving template: ${template.id}');
    await _store.saveTemplate(template);
    Log.d('TemplateRepository', 'Template saved: ${template.id}');
  }

  /// Delete a template permanently.
  Future<void> delete(String id) async {
    Log.d('TemplateRepository', 'Deleting template: $id');
    await _store.deleteTemplate(id);
  }

  /// Get a template by ID.
  Future<RecipeTemplate?> getById(String id) async {
    return await _store.getTemplateById(id);
  }

  /// Ensures a template exists, creating it if it doesn't.
  /// Returns true if template was created, false if it already existed.
  Future<bool> ensureExists(RecipeTemplate template) async {
    final created = await _store.ensureTemplateExists(template);
    if (created) {
      Log.d('TemplateRepository', 'Created template: ${template.id}');
    } else {
      Log.d('TemplateRepository', 'Template already exists: ${template.id}');
    }
    return created;
  }
}
