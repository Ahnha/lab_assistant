import 'lab_run.dart';
import 'formula_phase.dart';

/// Helper to resolve ingredient section keys for a given section ID.
/// This is used to determine which ingredient check keys belong to a section.
class IngredientSectionHelper {
  /// Generates a stable fallback ID from item name using simple hash.
  /// This ensures consistent keys even when item.id is missing.
  static String _generateStableId(String name, int index) {
    // Simple hash function for stability (no external dependencies)
    int hashValue = 0;
    for (int i = 0; i < name.length; i++) {
      hashValue = ((hashValue << 5) - hashValue) + name.codeUnitAt(i);
    }
    // Use absolute value and combine with index for uniqueness
    final hashInt = hashValue < 0 ? -hashValue : hashValue;
    final hashStr = hashInt.toRadixString(16).padLeft(8, '0');
    return '${hashStr}_$index';
  }

  /// Generates an ingredient check key for a phase item.
  /// Uses stable fallback ID if item.id is empty.
  static String getPhaseItemKey(
    String phaseId,
    String itemId,
    String itemName,
    int index,
  ) {
    final effectiveItemId = itemId.isNotEmpty
        ? itemId
        : _generateStableId(itemName, index);
    return 'phase:$phaseId:$effectiveItemId';
  }

  /// Generates an ingredient check key for a soap oil.
  /// Uses stable fallback ID if oil.id is empty.
  static String getSoapOilKey(String oilId, String oilName, int index) {
    final effectiveOilId = oilId.isNotEmpty
        ? oilId
        : _generateStableId(oilName, index);
    return 'soap:oils:$effectiveOilId';
  }

  /// Gets all ingredient check keys for a given section ID.
  ///
  /// For cream:
  /// - sectionId = "phase:pA" => keys "phase:pA:<itemId>" for all items in phase A
  ///
  /// For soap:
  /// - sectionId = "soap:oils" => keys "soap:oils:<oilId>" for all oils
  /// - sectionId = "soap:lyeWater" => keys for lye/water (currently not checkable)
  static List<String> getSectionKeys(LabRun run, String sectionId) {
    if (run.formula == null) {
      return [];
    }

    final formula = run.formula!;

    // Handle cream phases
    if (sectionId.startsWith('phase:')) {
      // Extract phase ID from sectionId (e.g., "phase:pA" -> "pA")
      final phaseId = sectionId.replaceFirst('phase:', '');

      if (formula.isCreamStyle && formula.phases != null) {
        // Find the phase by matching the ID
        FormulaPhase? phase;
        for (final p in formula.phases!) {
          // Convert phase order to letter (A=1, B=2, etc.)
          final phaseLetter = String.fromCharCode(65 + (p.order - 1));
          final expectedId = 'p$phaseLetter';
          if (p.id == phaseId || p.id == expectedId) {
            phase = p;
            break;
          }
        }

        if (phase == null) {
          return []; // Phase not found
        }

        // Generate keys for ALL items in this phase
        // Use stable fallback if item.id is missing or empty
        // Use the phaseId extracted from sectionId (not phase.id) to ensure consistency
        // with how keys are generated in the UI
        return phase.items.asMap().entries.map((entry) {
          final item = entry.value;
          final index = entry.key;
          return getPhaseItemKey(phaseId, item.id, item.name, index);
        }).toList();
      }
    }

    // Handle soap oils
    if (sectionId == 'soap:oils') {
      if (formula.isSoapStyle && formula.oils != null) {
        // Generate keys for ALL oils
        // Use stable fallback if oil.id is missing or empty
        return formula.oils!.asMap().entries.map((entry) {
          final oil = entry.value;
          final index = entry.key;
          return getSoapOilKey(oil.id, oil.name, index);
        }).toList();
      }
    }

    // Handle soap lye/water (currently not checkable, but return empty for now)
    if (sectionId == 'soap:lyeWater') {
      return []; // Lye/Water are not checkable ingredients
    }

    return [];
  }
}
