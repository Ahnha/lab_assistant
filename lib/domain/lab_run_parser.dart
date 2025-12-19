import 'dart:convert';
import 'lab_run.dart';
import 'recipe_ref.dart';
import 'procedure_step.dart';
import 'formula.dart';

/// Tolerant parser for LabRun JSON data.
/// Handles common parsing issues like string numbers, missing fields, etc.
class LabRunParser {
  /// Parses a num value from JSON, accepting int, double, or string.
  /// Returns null if parsing fails.
  static num? parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Parses an int value from JSON, accepting int or string.
  /// Returns null if parsing fails.
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Parses a double value from JSON, accepting int, double, or string.
  /// Returns null if parsing fails.
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Parses a DateTime from JSON string or ISO8601 format.
  /// Returns current time if parsing fails.
  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Parses a LabRun from JSON string or Map.
  /// Throws FormatException if JSON is invalid.
  static LabRun parse(String jsonString) {
    try {
      final jsonData = jsonDecode(jsonString);
      return parseFromMap(jsonData as Map<String, dynamic>);
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
  }

  /// Parses a LabRun from a Map.
  /// Uses tolerant parsing for all fields.
  static LabRun parseFromMap(Map<String, dynamic> json) {
    // Parse createdAt with fallback
    final createdAt = parseDateTime(json['createdAt']);

    // Parse recipe
    final recipeJson = json['recipe'];
    if (recipeJson == null || recipeJson is! Map<String, dynamic>) {
      throw FormatException('Missing or invalid recipe field');
    }
    final recipe = RecipeRef.fromJson(recipeJson);

    // Parse steps
    final stepsJson = json['steps'];
    if (stepsJson == null || stepsJson is! List) {
      throw FormatException('Missing or invalid steps field');
    }
    final steps = (stepsJson)
        .map((stepJson) {
          try {
            return ProcedureStep.fromJson(stepJson as Map<String, dynamic>);
          } catch (e) {
            // Log but continue - skip invalid steps
            return null;
          }
        })
        .whereType<ProcedureStep>()
        .toList();

    // Parse optional fields
    final formula = json['formula'] != null
        ? Formula.fromJson(json['formula'] as Map<String, dynamic>)
        : null;

    // Parse finishedAt
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
      id: json['id'] as String? ?? '',
      createdAt: createdAt,
      recipe: recipe,
      batchCode: json['batchCode'] as String?,
      steps: steps,
      notes: json['notes'] as String?,
      archived: json['archived'] as bool? ?? false,
      finishedAt: finishedAt,
      formula: formula,
      templateId: json['templateId'] as String?,
      ingredientChecks: ingredientChecksMap,
    );
  }
}
