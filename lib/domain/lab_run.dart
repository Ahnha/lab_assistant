import 'recipe_ref.dart';
import 'procedure_step.dart';
import 'step_status.dart';
import 'step_kind.dart';
import 'formula.dart';

class LabRun {
  final String id;
  final DateTime createdAt;
  final RecipeRef recipe;
  final String? batchCode;
  final List<ProcedureStep> steps;
  String? notes;
  bool archived;
  DateTime? finishedAt;
  Formula? formula;
  // Optional reference to template this run was created from
  final String? templateId;
  // Run-specific ingredient check states (only stored in runs, not templates)
  // Key format: "phase:<phaseId>:<itemId>" for cream, "soap:oils:<oilId>" for soap oils
  final Map<String, bool> ingredientChecks;

  LabRun({
    required this.id,
    required this.createdAt,
    required this.recipe,
    this.batchCode,
    required this.steps,
    this.notes,
    this.archived = false,
    this.finishedAt,
    this.formula,
    this.templateId,
    Map<String, bool>? ingredientChecks,
  }) : ingredientChecks = ingredientChecks ?? {};

  // Exclude section steps from completion count
  int get completedSteps => steps
      .where(
        (step) =>
            step.kind != StepKind.section && step.status == StepStatus.done,
      )
      .length;
  int get totalSteps =>
      steps.where((step) => step.kind != StepKind.section).length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'recipe': recipe.toJson(),
      'batchCode': batchCode,
      'steps': steps.map((step) => step.toJson()).toList(),
      'notes': notes,
      'archived': archived,
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
      if (formula != null) 'formula': formula!.toJson(),
      if (templateId != null) 'templateId': templateId,
      if (ingredientChecks.isNotEmpty) 'ingredientChecks': ingredientChecks,
    };
  }

  factory LabRun.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    DateTime? finishedAt;
    if (json['finishedAt'] != null) {
      try {
        finishedAt = DateTime.parse(json['finishedAt'] as String);
      } catch (e) {
        finishedAt = null;
      }
    }

    // Parse ingredientChecks
    Map<String, bool> ingredientChecksMap = {};
    if (json['ingredientChecks'] != null) {
      final checksJson = json['ingredientChecks'] as Map<String, dynamic>;
      ingredientChecksMap = checksJson.map(
        (key, value) => MapEntry(key, value as bool),
      );
    }

    return LabRun(
      id: json['id'] as String,
      createdAt: createdAt,
      recipe: RecipeRef.fromJson(json['recipe'] as Map<String, dynamic>),
      batchCode: json['batchCode'] as String?,
      steps: (json['steps'] as List)
          .map((step) => ProcedureStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      archived: json['archived'] as bool? ?? false,
      finishedAt: finishedAt,
      formula: json['formula'] != null
          ? Formula.fromJson(json['formula'] as Map<String, dynamic>)
          : null,
      templateId: json['templateId'] as String?,
      ingredientChecks: ingredientChecksMap,
    );
  }
}
