import 'recipe_kind.dart';
import 'formula.dart';
import 'procedure_step.dart';

/// Template for creating lab runs.
/// Templates are recipe definitions that can be used to start new runs.
/// System templates (isSystem=true) are built-in examples and are never shown as runs.
class RecipeTemplate {
  final String id;
  final String name;
  final RecipeKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Formula? formula;
  final List<ProcedureStep> steps;
  final bool isSystem;

  RecipeTemplate({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.formula,
    required this.steps,
    this.isSystem = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (formula != null) 'formula': formula!.toJson(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'isSystem': isSystem,
    };
  }

  factory RecipeTemplate.fromJson(Map<String, dynamic> json) {
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

    DateTime updatedAt;
    if (json['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(json['updatedAt'] as String);
      } catch (e) {
        updatedAt = DateTime.now();
      }
    } else {
      updatedAt = createdAt;
    }

    return RecipeTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: RecipeKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => RecipeKind.soap,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      formula: json['formula'] != null
          ? Formula.fromJson(json['formula'] as Map<String, dynamic>)
          : null,
      steps: (json['steps'] as List)
          .map((step) => ProcedureStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  /// Creates a copy with updated timestamp
  RecipeTemplate copyWith({
    String? id,
    String? name,
    RecipeKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
    Formula? formula,
    List<ProcedureStep>? steps,
    bool? isSystem,
  }) {
    return RecipeTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      formula: formula ?? this.formula,
      steps: steps ?? this.steps,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
