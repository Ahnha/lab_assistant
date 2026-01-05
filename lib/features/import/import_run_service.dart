import '../../domain/lab_run.dart';
import '../../domain/lab_run_parser.dart';
import '../../domain/lab_run_validator.dart';

/// Result of importing a run from JSON
class ImportResult {
  final bool success;
  final LabRun? run;
  final List<String> errors;

  const ImportResult({
    required this.success,
    this.run,
    required this.errors,
  });
}

/// Service for importing LabRun from JSON.
/// Pure function that parses and validates JSON without side effects.
class ImportRunService {
  /// Imports a LabRun from JSON string.
  /// Returns ImportResult with success status, parsed run (if successful), and errors (if any).
  static ImportResult importRunFromJson(String jsonText) {
    // Validate JSON structure first
    final structureErrors = LabRunValidator.validateJsonStructure(jsonText);
    if (structureErrors.isNotEmpty) {
      return ImportResult(
        success: false,
        errors: structureErrors,
      );
    }

    try {
      // Parse JSON
      final run = LabRunParser.parse(jsonText);

      // Validate parsed run
      final validationErrors = LabRunValidator.validate(run);
      if (validationErrors.isNotEmpty) {
        return ImportResult(
          success: false,
          errors: validationErrors,
        );
      }

      return ImportResult(
        success: true,
        run: run,
        errors: [],
      );
    } catch (e) {
      return ImportResult(
        success: false,
        errors: ['Failed to parse JSON: ${e.toString()}'],
      );
    }
  }
}
