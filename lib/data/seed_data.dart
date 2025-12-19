import '../domain/lab_run.dart';
import '../domain/recipe_ref.dart';
import '../domain/recipe_kind.dart';
import '../domain/procedure_step.dart';
import '../domain/step_kind.dart';
import '../domain/step_status.dart';
import '../domain/checklist_item.dart';
import '../domain/formula.dart';
import '../domain/soap_formula.dart';

class SeedData {
  static LabRun createMockSoapRun() {
    final now = DateTime.now();
    return LabRun(
      id: '${now.microsecondsSinceEpoch}_soap',
      createdAt: now,
      recipe: RecipeRef(
        id: 'recipe-soap-001',
        kind: RecipeKind.soap,
        name: 'Basic Cold Process Soap',
        defaultBatchSizeGrams: 1000,
      ),
      batchCode:
          'SOAP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
      formula: Formula(
        batchSizeGrams: 1000.0,
        oilsTotalGrams: 700.0,
        oils: [
          SoapOil(id: 'oil-1', name: 'Olive Oil', grams: 350.0, percent: 50.0),
          SoapOil(
            id: 'oil-2',
            name: 'Coconut Oil',
            grams: 210.0,
            percent: 30.0,
          ),
          SoapOil(id: 'oil-3', name: 'Palm Oil', grams: 140.0, percent: 20.0),
        ],
        lye: SoapLye(name: 'Sodium Hydroxide', grams: 100.0),
        water: SoapWater(name: 'Distilled Water', grams: 200.0),
        superfatPercent: 5.0,
      ),
      steps: [
        ProcedureStep(
          id: 'step-1',
          kind: StepKind.checklist,
          title: 'Sanitize Equipment',
          description: 'Clean and sanitize all equipment before starting',
          order: 1,
          status: StepStatus.todo,
          items: [
            ChecklistItem(id: 'item-1', label: 'Stainless steel pot'),
            ChecklistItem(id: 'item-2', label: 'Stick blender'),
            ChecklistItem(id: 'item-3', label: 'Mold'),
            ChecklistItem(id: 'item-4', label: 'Measuring cups'),
          ],
        ),
        ProcedureStep(
          id: 'step-2',
          kind: StepKind.instruction,
          title: 'Prepare Lye Solution',
          description:
              'Carefully mix lye with water. Always add lye to water, never reverse. Work in well-ventilated area.',
          order: 2,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-3',
          kind: StepKind.instruction,
          title: 'Melt Oils',
          description: 'Heat oils to 100-110°F (38-43°C) in a double boiler',
          order: 3,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-4',
          kind: StepKind.instruction,
          title: 'Combine Lye and Oils',
          description: 'Slowly pour lye solution into oils while stirring',
          order: 4,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-5',
          kind: StepKind.instruction,
          title: 'Reach Trace',
          description:
              'Blend until mixture reaches trace (leaves a trail when drizzled)',
          order: 5,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-6',
          kind: StepKind.instruction,
          title: 'Pour into Mold',
          description: 'Pour traced soap into prepared mold and smooth the top',
          order: 6,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-7',
          kind: StepKind.instruction,
          title: 'Insulate',
          description: 'Cover mold with towel or blanket to retain heat',
          order: 7,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-8',
          kind: StepKind.timer,
          title: 'Cure Time',
          description: 'Allow soap to cure in mold',
          order: 8,
          status: StepStatus.todo,
          timerSeconds: 24 * 60 * 60, // 24 hours
        ),
        ProcedureStep(
          id: 'step-9',
          kind: StepKind.checklist,
          title: 'Unmold and Cut',
          description: 'Remove soap from mold and cut into bars',
          order: 9,
          status: StepStatus.todo,
          items: [
            ChecklistItem(
              id: 'item-1',
              label: 'Soap releases easily from mold',
            ),
            ChecklistItem(id: 'item-2', label: 'Cut into uniform bars'),
            ChecklistItem(id: 'item-3', label: 'Place bars on curing rack'),
          ],
        ),
        ProcedureStep(
          id: 'step-10',
          kind: StepKind.note,
          title: 'Cure Notes',
          description: 'Record curing observations and final pH',
          order: 10,
          status: StepStatus.todo,
        ),
      ],
    );
  }

  static LabRun createMockCreamRun() {
    final now = DateTime.now();
    return LabRun(
      id: '${now.microsecondsSinceEpoch}_cream',
      createdAt: now,
      recipe: RecipeRef(
        id: 'recipe-cream-001',
        kind: RecipeKind.cream,
        name: 'Moisturizing Face Cream',
        defaultBatchSizeGrams: 500,
      ),
      batchCode:
          'CREAM-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
      steps: [
        ProcedureStep(
          id: 'step-1',
          kind: StepKind.instruction,
          title: 'Phase A: Water Phase',
          description:
              'Combine water, glycerin, and water-soluble ingredients. Heat to 70°C.',
          order: 1,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-2',
          kind: StepKind.instruction,
          title: 'Phase B: Oil Phase',
          description: 'Combine oils, butters, and emulsifiers. Heat to 70°C.',
          order: 2,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-3',
          kind: StepKind.inputNumber,
          title: 'Temperature Check',
          description: 'Verify both phases are at target temperature',
          order: 3,
          status: StepStatus.todo,
          unit: '°C',
          value: null,
        ),
        ProcedureStep(
          id: 'step-4',
          kind: StepKind.instruction,
          title: 'Emulsify',
          description:
              'Slowly add Phase A to Phase B while blending. Blend until smooth and creamy.',
          order: 4,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-5',
          kind: StepKind.timer,
          title: 'Cool Down Phase',
          description: 'Allow mixture to cool to 40°C before adding actives',
          order: 5,
          status: StepStatus.todo,
          timerSeconds: 30 * 60, // 30 minutes
        ),
        ProcedureStep(
          id: 'step-6',
          kind: StepKind.instruction,
          title: 'Add Active Ingredients',
          description:
              'Add vitamins, extracts, and other heat-sensitive actives',
          order: 6,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-7',
          kind: StepKind.instruction,
          title: 'Add Preservative',
          description: 'Add preservative and mix thoroughly',
          order: 7,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-8',
          kind: StepKind.inputNumber,
          title: 'pH Check',
          description: 'Measure and record pH of final product',
          order: 8,
          status: StepStatus.todo,
          unit: 'pH',
          value: null,
        ),
        ProcedureStep(
          id: 'step-9',
          kind: StepKind.note,
          title: 'Quality Notes',
          description: 'Record texture, color, and any observations',
          order: 9,
          status: StepStatus.todo,
        ),
        ProcedureStep(
          id: 'step-10',
          kind: StepKind.checklist,
          title: 'Fill Containers',
          description: 'Fill and label containers',
          order: 10,
          status: StepStatus.todo,
          items: [
            ChecklistItem(id: 'item-1', label: 'Containers sanitized'),
            ChecklistItem(id: 'item-2', label: 'Filled to proper level'),
            ChecklistItem(id: 'item-3', label: 'Labels applied'),
            ChecklistItem(id: 'item-4', label: 'Batch code recorded'),
          ],
        ),
      ],
    );
  }
}
