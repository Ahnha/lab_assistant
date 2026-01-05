import 'package:flutter_test/flutter_test.dart';
import 'package:lab_assistant/features/import/import_run_service.dart';
import 'dart:io';

void main() {
  group('Import Run Fixtures', () {
    test('sample_run_soap.json parses and validates successfully', () {
      final fixturePath = 'test/fixtures/sample_run_soap.json';
      final jsonContent = File(fixturePath).readAsStringSync();

      final result = ImportRunService.importRunFromJson(jsonContent);

      expect(result.success, isTrue, reason: 'Import should succeed');
      expect(result.run, isNotNull, reason: 'Parsed run should not be null');
      expect(result.errors, isEmpty, reason: 'Should have no errors');
      expect(result.run!.id, equals('sample-soap-test'));
      expect(result.run!.recipe.kind.name, equals('soap'));
      expect(result.run!.recipe.name, equals('Basic Cold Process Soap'));
      expect(result.run!.steps.length, greaterThan(0));
    });

    test('sample_run_cream.json parses and validates successfully', () {
      final fixturePath = 'test/fixtures/sample_run_cream.json';
      final jsonContent = File(fixturePath).readAsStringSync();

      final result = ImportRunService.importRunFromJson(jsonContent);

      expect(result.success, isTrue, reason: 'Import should succeed');
      expect(result.run, isNotNull, reason: 'Parsed run should not be null');
      expect(result.errors, isEmpty, reason: 'Should have no errors');
      expect(result.run!.id, equals('sample-cream-test'));
      expect(result.run!.recipe.kind.name, equals('cream'));
      expect(result.run!.recipe.name, equals('Basic Emulsifying Cream'));
      expect(result.run!.steps.length, greaterThan(0));
      expect(result.run!.formula, isNotNull);
      expect(result.run!.formula!.phases, isNotNull);
      expect(result.run!.formula!.phases!.length, equals(3));
    });

    test('invalid JSON returns error result', () {
      const invalidJson = '{"invalid": json}';

      final result = ImportRunService.importRunFromJson(invalidJson);

      expect(result.success, isFalse, reason: 'Import should fail');
      expect(result.run, isNull, reason: 'Parsed run should be null');
      expect(result.errors, isNotEmpty, reason: 'Should have errors');
    });

    test('empty JSON returns error result', () {
      const emptyJson = '';

      final result = ImportRunService.importRunFromJson(emptyJson);

      expect(result.success, isFalse, reason: 'Import should fail');
      expect(result.run, isNull, reason: 'Parsed run should be null');
      expect(result.errors, isNotEmpty, reason: 'Should have errors');
    });
  });
}
