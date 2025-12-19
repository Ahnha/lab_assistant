import 'lab_run.dart';
import 'formula.dart';
import 'soap_formula.dart';

/// Pure domain functions for scaling lab run formulas.
/// These functions are stateless and do not perform any I/O operations.

/// Scales soap oils to a new total oils weight.
///
/// Rules:
/// - Updates oilsTotalGrams to the new value
/// - Recalculates each oil grams = oilsTotalGrams * (percent / 100)
/// - Keeps 2 decimal places precision
/// - Does NOT modify lye/water grams
///
/// Returns a new LabRun with updated formula.
LabRun scaleSoapOils(LabRun run, double newOilsTotalGrams) {
  if (run.formula == null || !run.formula!.isSoapStyle) {
    return run;
  }

  final formula = run.formula!;
  if (formula.oils == null || formula.oils!.isEmpty) {
    return run;
  }

  // Recalculate each oil based on percentage
  final scaledOils = formula.oils!.map((oil) {
    if (oil.percent != null) {
      final newGrams = _roundTo2Decimals(
        newOilsTotalGrams * oil.percent! / 100.0,
      );
      return SoapOil(
        id: oil.id,
        name: oil.name,
        grams: newGrams,
        percent: oil.percent,
      );
    }
    // If no percent, keep grams as-is
    return oil;
  }).toList();

  final updatedFormula = Formula(
    batchSizeGrams: formula.batchSizeGrams,
    phases: formula.phases,
    oilsTotalGrams: _roundTo2Decimals(newOilsTotalGrams),
    oils: scaledOils,
    lye: formula.lye, // Keep unchanged
    water: formula.water, // Keep unchanged
    superfatPercent: formula.superfatPercent,
  );

  return LabRun(
    id: run.id,
    createdAt: run.createdAt,
    recipe: run.recipe,
    batchCode: run.batchCode,
    steps: run.steps,
    notes: run.notes,
    archived: run.archived,
    finishedAt: run.finishedAt,
    formula: updatedFormula,
    templateId: run.templateId,
    ingredientChecks: run.ingredientChecks,
  );
}

/// Scales cream/cosmetic phase items to a new batch size.
///
/// Rules:
/// - If items have percent (percent of TOTAL batch):
///   grams = batchSizeGrams * (percent / 100), keep 2 decimals
/// - Items without percent keep their grams as-is
///
/// Returns a new LabRun with updated formula.
LabRun scalePhaseItems(LabRun run, double newBatchSizeGrams) {
  if (run.formula == null || !run.formula!.isCreamStyle) {
    return run;
  }

  final formula = run.formula!;
  if (formula.phases == null || formula.phases!.isEmpty) {
    return run;
  }

  // Scale each phase's items
  final scaledPhases = formula.phases!.map((phase) {
    final scaledItems = phase.items.map((item) {
      if (item.percent != null) {
        final newGrams = _roundTo2Decimals(
          newBatchSizeGrams * item.percent! / 100.0,
        );
        return item.copyWith(grams: newGrams);
      }
      // If no percent, keep grams as-is
      return item;
    }).toList();

    return phase.copyWith(items: scaledItems);
  }).toList();

  final updatedFormula = Formula(
    batchSizeGrams: _roundTo2Decimals(newBatchSizeGrams),
    phases: scaledPhases,
    oilsTotalGrams: formula.oilsTotalGrams,
    oils: formula.oils,
    lye: formula.lye,
    water: formula.water,
    superfatPercent: formula.superfatPercent,
  );

  return LabRun(
    id: run.id,
    createdAt: run.createdAt,
    recipe: run.recipe,
    batchCode: run.batchCode,
    steps: run.steps,
    notes: run.notes,
    archived: run.archived,
    finishedAt: run.finishedAt,
    formula: updatedFormula,
    templateId: run.templateId,
    ingredientChecks: run.ingredientChecks,
  );
}

/// Rounds a double to 2 decimal places.
double _roundTo2Decimals(double value) {
  return (value * 100).roundToDouble() / 100.0;
}

/// Calculates the total grams of oils with percentages in a soap formula.
/// Returns null if formula is not soap-style or has no oils.
double? calculateSoapOilsTotal(Formula formula) {
  if (!formula.isSoapStyle || formula.oils == null) {
    return null;
  }

  double total = 0.0;
  for (final oil in formula.oils!) {
    if (oil.percent != null) {
      total += oil.grams;
    }
  }
  return _roundTo2Decimals(total);
}

/// Calculates the total grams of items with percentages in a cream formula.
/// Returns null if formula is not cream-style or has no phases.
double? calculateCreamItemsTotal(Formula formula) {
  if (!formula.isCreamStyle || formula.phases == null) {
    return null;
  }

  double total = 0.0;
  for (final phase in formula.phases!) {
    for (final item in phase.items) {
      if (item.percent != null) {
        total += item.grams;
      }
    }
  }
  return _roundTo2Decimals(total);
}

/// Calculates the total percent of oils with percentages in a soap formula.
/// Returns null if formula is not soap-style or has no oils.
double? calculateSoapOilsTotalPercent(Formula formula) {
  if (!formula.isSoapStyle || formula.oils == null) {
    return null;
  }

  double total = 0.0;
  for (final oil in formula.oils!) {
    if (oil.percent != null) {
      total += oil.percent!;
    }
  }
  return _roundTo2Decimals(total);
}

/// Calculates the total percent of items with percentages in a cream formula.
/// Returns null if formula is not cream-style or has no phases.
double? calculateCreamItemsTotalPercent(Formula formula) {
  if (!formula.isCreamStyle || formula.phases == null) {
    return null;
  }

  double total = 0.0;
  for (final phase in formula.phases!) {
    for (final item in phase.items) {
      if (item.percent != null) {
        total += item.percent!;
      }
    }
  }
  return _roundTo2Decimals(total);
}
