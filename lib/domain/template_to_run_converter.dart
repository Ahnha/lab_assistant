import 'recipe_template.dart';
import 'lab_run.dart';
import 'recipe_ref.dart';
import 'recipe_kind.dart';
import 'procedure_step.dart';
import 'step_status.dart';
import '../app/log.dart';

/// Converts a RecipeTemplate to a new LabRun instance.
/// This creates a fresh run with new ID, reset steps, and optional scaling.
class TemplateToRunConverter {
  /// Creates a new LabRun from a template.
  /// - Generates new run ID
  /// - Sets createdAt to now
  /// - Resets all step statuses to todo
  /// - Copies formula (optionally scaled to new batch size)
  /// - Sets templateId reference
  static LabRun createRunFromTemplate(
    RecipeTemplate template, {
    double? batchSizeGrams,
  }) {
    final now = DateTime.now();
    final runId = 'run_${now.microsecondsSinceEpoch}_${template.kind.name}';

    // Reset all steps to todo status
    final steps = template.steps.map((step) {
      return ProcedureStep(
        id: step.id,
        kind: step.kind,
        title: step.title,
        description: step.description,
        order: step.order,
        status: StepStatus.todo,
        items: step.items,
        timerSeconds: step.timerSeconds,
        unit: step.unit,
        ingredientSectionId: step.ingredientSectionId,
        ingredientSectionLabel: step.ingredientSectionLabel,
      );
    }).toList();

    // Copy formula, optionally scaling
    var formula = template.formula;
    if (formula != null && batchSizeGrams != null) {
      formula = formula.scaleToBatchSize(batchSizeGrams);
    }

    // Generate batch code
    final batchCode = _generateBatchCode(template.kind, now);

    Log.d(
      'TemplateToRunConverter',
      'Created run $runId from template ${template.id}',
    );

    return LabRun(
      id: runId,
      createdAt: now,
      recipe: RecipeRef(
        id: template.id,
        kind: template.kind,
        name: template.name,
        defaultBatchSizeGrams:
            batchSizeGrams?.toInt() ??
            formula?.batchSizeGrams?.toInt() ??
            template.formula?.batchSizeGrams?.toInt(),
      ),
      batchCode: batchCode,
      steps: steps,
      formula: formula,
      templateId: template.id,
      ingredientChecks: {}, // New runs start with empty checks
    );
  }

  static String _generateBatchCode(RecipeKind kind, DateTime now) {
    final prefix = kind == RecipeKind.soap ? 'SOAP' : 'CREAM';
    return '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }
}
