import 'recipe_ref.dart';
import 'procedure_step.dart';
import 'step_status.dart';
import 'formula.dart';

class LabRun {
  final String id;
  final DateTime createdAt;
  final RecipeRef recipe;
  final String? batchCode;
  final List<ProcedureStep> steps;
  String? notes;
  bool archived;
  Formula? formula;

  LabRun({
    required this.id,
    required this.createdAt,
    required this.recipe,
    this.batchCode,
    required this.steps,
    this.notes,
    this.archived = false,
    this.formula,
  });

  int get completedSteps =>
      steps.where((step) => step.status == StepStatus.done).length;
  int get totalSteps => steps.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'recipe': recipe.toJson(),
      'batchCode': batchCode,
      'steps': steps.map((step) => step.toJson()).toList(),
      'notes': notes,
      'archived': archived,
      if (formula != null) 'formula': formula!.toJson(),
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
      formula: json['formula'] != null
          ? Formula.fromJson(json['formula'] as Map<String, dynamic>)
          : null,
    );
  }
}
