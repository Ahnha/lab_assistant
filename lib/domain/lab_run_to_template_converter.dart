import 'lab_run.dart';
import 'recipe_template.dart';
import 'recipe_kind.dart';
import '../app/log.dart';

/// Converts a LabRun to a RecipeTemplate.
/// Used when importing a run JSON as a template.
class LabRunToTemplateConverter {
  /// Creates a RecipeTemplate from a LabRun.
  /// - Uses recipe name as template name
  /// - Uses recipe kind as template kind
  /// - Generates new template ID if not provided
  /// - Sets isSystem to false (user-created template)
  /// - Copies formula and steps
  static RecipeTemplate createTemplateFromRun(
    LabRun run, {
    String? templateId,
  }) {
    final now = DateTime.now();
    final id =
        templateId ??
        'template_${now.microsecondsSinceEpoch}_${run.recipe.kind.name}';

    Log.d(
      'LabRunToTemplateConverter',
      'Creating template $id from run ${run.id}',
    );

    return RecipeTemplate(
      id: id,
      name: run.recipe.name,
      kind: run.recipe.kind,
      createdAt: now,
      updatedAt: now,
      formula: run.formula,
      steps: run.steps,
      isSystem: false,
    );
  }
}
