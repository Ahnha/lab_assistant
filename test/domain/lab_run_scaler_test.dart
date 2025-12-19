import 'package:flutter_test/flutter_test.dart';
import 'package:lab_assistant/domain/lab_run.dart';
import 'package:lab_assistant/domain/formula.dart';
import 'package:lab_assistant/domain/soap_formula.dart';
import 'package:lab_assistant/domain/formula_phase.dart';
import 'package:lab_assistant/domain/formula_item.dart';
import 'package:lab_assistant/domain/recipe_ref.dart';
import 'package:lab_assistant/domain/recipe_kind.dart';
import 'package:lab_assistant/domain/lab_run_scaler.dart';

void main() {
  group('scaleSoapOils', () {
    test(
      'scales oils correctly based on percentages with 2 decimal precision',
      () {
        final run = LabRun(
          id: 'test-1',
          createdAt: DateTime.now(),
          recipe: RecipeRef(
            id: 'recipe-1',
            kind: RecipeKind.soap,
            name: 'Test Soap',
          ),
          steps: [],
          formula: Formula(
            oilsTotalGrams: 700.0,
            oils: [
              SoapOil(
                id: 'oil-1',
                name: 'Olive Oil',
                grams: 350.0,
                percent: 50.0,
              ),
              SoapOil(
                id: 'oil-2',
                name: 'Coconut Oil',
                grams: 210.0,
                percent: 30.0,
              ),
              SoapOil(
                id: 'oil-3',
                name: 'Palm Oil',
                grams: 140.0,
                percent: 20.0,
              ),
            ],
            lye: SoapLye(name: 'Sodium Hydroxide', grams: 100.0),
            water: SoapWater(name: 'Distilled Water', grams: 200.0),
          ),
        );

        // Scale to 1000g total oils
        final scaled = scaleSoapOils(run, 1000.0);

        expect(scaled.formula?.oilsTotalGrams, 1000.0);
        expect(scaled.formula?.oils?.length, 3);

        // 50% of 1000 = 500.00
        expect(scaled.formula?.oils?[0].grams, 500.0);
        // 30% of 1000 = 300.00
        expect(scaled.formula?.oils?[1].grams, 300.0);
        // 20% of 1000 = 200.00
        expect(scaled.formula?.oils?[2].grams, 200.0);

        // Lye and water should remain unchanged
        expect(scaled.formula?.lye?.grams, 100.0);
        expect(scaled.formula?.water?.grams, 200.0);
      },
    );

    test('handles decimal percentages correctly (e.g., 33.33%)', () {
      final run = LabRun(
        id: 'test-2',
        createdAt: DateTime.now(),
        recipe: RecipeRef(
          id: 'recipe-2',
          kind: RecipeKind.soap,
          name: 'Test Soap',
        ),
        steps: [],
        formula: Formula(
          oilsTotalGrams: 300.0,
          oils: [
            SoapOil(id: 'oil-1', name: 'Oil A', grams: 100.0, percent: 33.33),
            SoapOil(id: 'oil-2', name: 'Oil B', grams: 100.0, percent: 33.33),
            SoapOil(id: 'oil-3', name: 'Oil C', grams: 100.0, percent: 33.34),
          ],
        ),
      );

      // Scale to 600g total oils
      final scaled = scaleSoapOils(run, 600.0);

      expect(scaled.formula?.oilsTotalGrams, 600.0);

      // 33.33% of 600 = 199.98, rounded to 2 decimals
      expect(scaled.formula?.oils?[0].grams, 199.98);
      expect(scaled.formula?.oils?[1].grams, 199.98);
      // 33.34% of 600 = 200.04, rounded to 2 decimals
      expect(scaled.formula?.oils?[2].grams, 200.04);
    });

    test('preserves oils without percentages unchanged', () {
      final run = LabRun(
        id: 'test-3',
        createdAt: DateTime.now(),
        recipe: RecipeRef(
          id: 'recipe-3',
          kind: RecipeKind.soap,
          name: 'Test Soap',
        ),
        steps: [],
        formula: Formula(
          oilsTotalGrams: 500.0,
          oils: [
            SoapOil(id: 'oil-1', name: 'Oil A', grams: 300.0, percent: 60.0),
            SoapOil(id: 'oil-2', name: 'Oil B', grams: 200.0, percent: null),
          ],
        ),
      );

      final scaled = scaleSoapOils(run, 1000.0);

      // Oil with percent should be scaled
      expect(scaled.formula?.oils?[0].grams, 600.0);
      // Oil without percent should remain unchanged
      expect(scaled.formula?.oils?[1].grams, 200.0);
    });
  });

  group('scalePhaseItems', () {
    test('scales cream phase items correctly based on percentages', () {
      final run = LabRun(
        id: 'test-4',
        createdAt: DateTime.now(),
        recipe: RecipeRef(
          id: 'recipe-4',
          kind: RecipeKind.cream,
          name: 'Test Cream',
        ),
        steps: [],
        formula: Formula(
          batchSizeGrams: 500.0,
          phases: [
            FormulaPhase(
              id: 'phase-1',
              name: 'Phase A',
              order: 1,
              items: [
                FormulaItem(
                  id: 'item-1',
                  name: 'Water',
                  grams: 300.0,
                  percent: 60.0,
                ),
                FormulaItem(
                  id: 'item-2',
                  name: 'Glycerin',
                  grams: 50.0,
                  percent: 10.0,
                ),
                FormulaItem(
                  id: 'item-3',
                  name: 'Oil',
                  grams: 150.0,
                  percent: 30.0,
                ),
              ],
            ),
          ],
        ),
      );

      // Scale to 1000g batch size
      final scaled = scalePhaseItems(run, 1000.0);

      expect(scaled.formula?.batchSizeGrams, 1000.0);

      // 60% of 1000 = 600.00
      expect(scaled.formula?.phases?[0].items[0].grams, 600.0);
      // 10% of 1000 = 100.00
      expect(scaled.formula?.phases?[0].items[1].grams, 100.0);
      // 30% of 1000 = 300.00
      expect(scaled.formula?.phases?[0].items[2].grams, 300.0);
    });

    test('preserves items without percentages unchanged', () {
      final run = LabRun(
        id: 'test-5',
        createdAt: DateTime.now(),
        recipe: RecipeRef(
          id: 'recipe-5',
          kind: RecipeKind.cream,
          name: 'Test Cream',
        ),
        steps: [],
        formula: Formula(
          batchSizeGrams: 500.0,
          phases: [
            FormulaPhase(
              id: 'phase-1',
              name: 'Phase A',
              order: 1,
              items: [
                FormulaItem(
                  id: 'item-1',
                  name: 'Water',
                  grams: 300.0,
                  percent: 60.0,
                ),
                FormulaItem(
                  id: 'item-2',
                  name: 'Preservative',
                  grams: 5.0,
                  percent: null,
                ),
              ],
            ),
          ],
        ),
      );

      final scaled = scalePhaseItems(run, 1000.0);

      // Item with percent should be scaled
      expect(scaled.formula?.phases?[0].items[0].grams, 600.0);
      // Item without percent should remain unchanged
      expect(scaled.formula?.phases?[0].items[1].grams, 5.0);
    });

    test('handles multiple phases correctly', () {
      final run = LabRun(
        id: 'test-6',
        createdAt: DateTime.now(),
        recipe: RecipeRef(
          id: 'recipe-6',
          kind: RecipeKind.cream,
          name: 'Test Cream',
        ),
        steps: [],
        formula: Formula(
          batchSizeGrams: 200.0,
          phases: [
            FormulaPhase(
              id: 'phase-1',
              name: 'Phase A',
              order: 1,
              items: [
                FormulaItem(
                  id: 'item-1',
                  name: 'Water',
                  grams: 100.0,
                  percent: 50.0,
                ),
              ],
            ),
            FormulaPhase(
              id: 'phase-2',
              name: 'Phase B',
              order: 2,
              items: [
                FormulaItem(
                  id: 'item-2',
                  name: 'Oil',
                  grams: 100.0,
                  percent: 50.0,
                ),
              ],
            ),
          ],
        ),
      );

      final scaled = scalePhaseItems(run, 400.0);

      expect(scaled.formula?.batchSizeGrams, 400.0);
      // Both phases should be scaled
      expect(scaled.formula?.phases?[0].items[0].grams, 200.0);
      expect(scaled.formula?.phases?[1].items[0].grams, 200.0);
    });
  });

  group('calculateSoapOilsTotal', () {
    test('calculates total of oils with percentages', () {
      final formula = Formula(
        oils: [
          SoapOil(id: 'oil-1', name: 'Oil A', grams: 100.0, percent: 50.0),
          SoapOil(id: 'oil-2', name: 'Oil B', grams: 60.0, percent: 30.0),
          SoapOil(id: 'oil-3', name: 'Oil C', grams: 40.0, percent: 20.0),
        ],
      );

      final total = calculateSoapOilsTotal(formula);
      expect(total, 200.0);
    });

    test('excludes oils without percentages', () {
      final formula = Formula(
        oils: [
          SoapOil(id: 'oil-1', name: 'Oil A', grams: 100.0, percent: 50.0),
          SoapOil(id: 'oil-2', name: 'Oil B', grams: 50.0, percent: null),
        ],
      );

      final total = calculateSoapOilsTotal(formula);
      expect(total, 100.0);
    });
  });

  group('calculateCreamItemsTotal', () {
    test('calculates total of items with percentages across all phases', () {
      final formula = Formula(
        phases: [
          FormulaPhase(
            id: 'phase-1',
            name: 'Phase A',
            order: 1,
            items: [
              FormulaItem(
                id: 'item-1',
                name: 'Water',
                grams: 100.0,
                percent: 50.0,
              ),
              FormulaItem(
                id: 'item-2',
                name: 'Glycerin',
                grams: 20.0,
                percent: 10.0,
              ),
            ],
          ),
          FormulaPhase(
            id: 'phase-2',
            name: 'Phase B',
            order: 2,
            items: [
              FormulaItem(
                id: 'item-3',
                name: 'Oil',
                grams: 80.0,
                percent: 40.0,
              ),
            ],
          ),
        ],
      );

      final total = calculateCreamItemsTotal(formula);
      expect(total, 200.0);
    });
  });
}
