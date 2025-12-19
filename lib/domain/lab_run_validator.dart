import 'lab_run.dart';

/// Validates LabRun data and returns friendly error messages.
class LabRunValidator {
  /// Validates a LabRun and returns a list of error messages.
  /// Returns empty list if valid.
  static List<String> validate(LabRun run) {
    final errors = <String>[];

    // Validate ID
    if (run.id.isEmpty) {
      errors.add('Run ID is required');
    }

    // Validate recipe
    if (run.recipe.name.isEmpty) {
      errors.add('Recipe name is required');
    }

    // Validate steps
    if (run.steps.isEmpty) {
      errors.add('At least one step is required');
    } else {
      // Check for duplicate step IDs
      final stepIds = <String>{};
      for (final step in run.steps) {
        if (stepIds.contains(step.id)) {
          errors.add('Duplicate step ID: ${step.id}');
        }
        stepIds.add(step.id);

        // Validate step has required fields
        if (step.title.isEmpty) {
          errors.add('Step ${step.id} is missing a title');
        }
      }
    }

    return errors;
  }

  /// Validates JSON string before parsing.
  /// Returns empty list if JSON structure is valid (doesn't validate content).
  static List<String> validateJsonStructure(String jsonString) {
    final errors = <String>[];

    if (jsonString.trim().isEmpty) {
      errors.add('JSON data is empty');
      return errors;
    }

    try {
      final json = jsonString.trim();
      if (!json.startsWith('{') || !json.endsWith('}')) {
        errors.add('JSON must be an object (starts with { and ends with })');
      }
    } catch (e) {
      errors.add('Invalid JSON format: ${e.toString()}');
    }

    return errors;
  }
}
