import 'formula_phase.dart';
import 'soap_formula.dart';

/// Unified formula model supporting both soap-style and cream-style formulas.
///
/// Parsing rules:
/// - If `phases` exists, treat as cream-style formula.
/// - If `oils` exists, treat as soap-style formula.
/// - If formula missing, app still works.
class Formula {
  // Common field
  final double? batchSizeGrams;

  // Cream-style fields
  final List<FormulaPhase>? phases;

  // Soap-style fields
  final double? oilsTotalGrams;
  final List<SoapOil>? oils;
  final SoapLye? lye;
  final SoapWater? water;
  final double? superfatPercent;

  Formula({
    this.batchSizeGrams,
    this.phases,
    this.oilsTotalGrams,
    this.oils,
    this.lye,
    this.water,
    this.superfatPercent,
  });

  /// Returns true if this is a cream-style formula (has phases)
  bool get isCreamStyle => phases != null && phases!.isNotEmpty;

  /// Returns true if this is a soap-style formula (has oils)
  bool get isSoapStyle => oils != null && oils!.isNotEmpty;

  /// Returns true if this formula has percentages available for scaling
  bool get hasPercentagesForScaling {
    if (isCreamStyle) {
      // For cream: check if any phase has items with percent
      return phases!.any(
        (phase) => phase.items.any((item) => item.percent != null),
      );
    } else if (isSoapStyle) {
      // For soap: all oils must have percent
      return oils!.isNotEmpty && oils!.every((oil) => oil.percent != null);
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (batchSizeGrams != null) {
      json['batchSizeGrams'] = batchSizeGrams;
    }

    // Cream-style fields
    if (phases != null) {
      json['phases'] = phases!.map((phase) => phase.toJson()).toList();
    }

    // Soap-style fields
    if (oilsTotalGrams != null) {
      json['oilsTotalGrams'] = oilsTotalGrams;
    }
    if (oils != null) {
      json['oils'] = oils!.map((oil) => oil.toJson()).toList();
    }
    if (lye != null) {
      json['lye'] = lye!.toJson();
    }
    if (water != null) {
      json['water'] = water!.toJson();
    }
    if (superfatPercent != null) {
      json['superfatPercent'] = superfatPercent;
    }

    return json;
  }

  factory Formula.fromJson(Map<String, dynamic> json) {
    // Parse cream-style (phases)
    List<FormulaPhase>? phases;
    if (json['phases'] != null) {
      phases = (json['phases'] as List)
          .map((phase) => FormulaPhase.fromJson(phase as Map<String, dynamic>))
          .toList();
    }

    // Parse soap-style (oils)
    double? oilsTotalGrams;
    List<SoapOil>? oils;
    SoapLye? lye;
    SoapWater? water;
    double? superfatPercent;

    if (json['oils'] != null) {
      final oilsTotalData = json['oilsTotalGrams'];
      oilsTotalGrams = (oilsTotalData is num) ? oilsTotalData.toDouble() : null;
      oils = (json['oils'] as List)
          .map((oil) => SoapOil.fromJson(oil as Map<String, dynamic>))
          .toList();
      lye = json['lye'] != null
          ? SoapLye.fromJson(json['lye'] as Map<String, dynamic>)
          : null;
      water = json['water'] != null
          ? SoapWater.fromJson(json['water'] as Map<String, dynamic>)
          : null;
      final superfatPercentData = json['superfatPercent'];
      if (superfatPercentData != null) {
        superfatPercent = (superfatPercentData is num)
            ? superfatPercentData.toDouble()
            : null;
      }
    }

    final batchSizeData = json['batchSizeGrams'];
    final batchSizeGrams = (batchSizeData is num)
        ? batchSizeData.toDouble()
        : null;

    return Formula(
      batchSizeGrams: batchSizeGrams,
      phases: phases,
      oilsTotalGrams: oilsTotalGrams,
      oils: oils,
      lye: lye,
      water: water,
      superfatPercent: superfatPercent,
    );
  }

  /// Creates a copy of this Formula with updated batch size and recalculated grams.
  /// For precise scaling with 2 decimal places, use lab_run_scaler functions instead.
  Formula scaleToBatchSize(double newBatchSize) {
    if (isCreamStyle) {
      return _scaleCreamFormula(newBatchSize);
    } else if (isSoapStyle) {
      return _scaleSoapFormula(newBatchSize);
    }
    return this;
  }

  Formula _scaleCreamFormula(double newBatchSize) {
    final scaledPhases = phases!.map((phase) {
      final scaledItems = phase.items.map((item) {
        if (item.percent != null) {
          final newGrams = (newBatchSize * item.percent! / 100).roundToDouble();
          return item.copyWith(grams: newGrams);
        }
        return item;
      }).toList();
      return phase.copyWith(items: scaledItems);
    }).toList();

    return Formula(
      batchSizeGrams: newBatchSize,
      phases: scaledPhases,
      oilsTotalGrams: oilsTotalGrams,
      oils: oils,
      lye: lye,
      water: water,
      superfatPercent: superfatPercent,
    );
  }

  Formula _scaleSoapFormula(double newBatchSize) {
    // For soap, calculate scale factor based on batch size change
    final oldBatchSize = batchSizeGrams ?? newBatchSize;
    final scaleFactor = oldBatchSize > 0 ? newBatchSize / oldBatchSize : 1.0;

    // Calculate target oils total
    // If oilsTotalGrams was not set, assume it was equal to old batch size
    final oldOilsTotal = oilsTotalGrams ?? oldBatchSize;
    final targetOilsTotal = (oldOilsTotal * scaleFactor).roundToDouble();

    final scaledOils = oils!.map((oil) {
      if (oil.percent != null) {
        // Calculate from percent of oils total
        final newGrams = (targetOilsTotal * oil.percent! / 100).roundToDouble();
        return SoapOil(
          id: oil.id,
          name: oil.name,
          grams: newGrams,
          percent: oil.percent,
        );
      } else {
        // Scale proportionally based on batch size
        final newGrams = (oil.grams * scaleFactor).roundToDouble();
        return SoapOil(
          id: oil.id,
          name: oil.name,
          grams: newGrams,
          percent: oil.percent,
        );
      }
    }).toList();

    // Scale lye and water proportionally based on batch size
    final scaledLye = lye != null
        ? SoapLye(
            name: lye!.name,
            grams: (lye!.grams * scaleFactor).roundToDouble(),
          )
        : null;

    final scaledWater = water != null
        ? SoapWater(
            name: water!.name,
            grams: (water!.grams * scaleFactor).roundToDouble(),
          )
        : null;

    return Formula(
      batchSizeGrams: newBatchSize,
      phases: phases,
      oilsTotalGrams: targetOilsTotal,
      oils: scaledOils,
      lye: scaledLye,
      water: scaledWater,
      superfatPercent: superfatPercent,
    );
  }
}
