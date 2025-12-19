import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/lab_run.dart';
import '../../domain/procedure_step.dart';
import '../../domain/step_status.dart';
import '../../domain/step_kind.dart';
import '../../domain/checklist_item.dart';
import '../../domain/ingredient_section_helper.dart';
import '../../data/lab_run_repository.dart';
import '../../app/log.dart';

/// Controller for managing a single lab run's state and business logic.
///
/// Responsibilities:
/// - Owns the LabRun instance
/// - Handles all mutations (checklist toggles, input values, status changes)
/// - Triggers debounced saves via repository (only on user actions, never on timer ticks)
/// - Notifies listeners when state changes
/// - Manages timer state and logic for timer steps
/// - Manages navigation context for ingredients (section tracking, auto-complete)
class RunController extends ChangeNotifier {
  final LabRunRepository _repository = LabRunRepository();
  LabRun _run;
  Timer? _saveDebounceTimer;
  bool _isSaving = false;
  final Map<String, Timer> _activeTimers = {};
  Function(String stepId, String stepTitle)? onTimerFinished;
  Function(String sectionId, String stepId)? onSectionCompleted;

  // Navigation context for ingredients
  String? _activeIngredientSectionId;
  String?
  _sourceStepId; // Step that opened ingredients (null if opened manually)

  String? get activeIngredientSectionId => _activeIngredientSectionId;
  String? get sourceStepId => _sourceStepId;

  RunController(this._run) {
    // Restore running timers from persisted state
    _restoreTimers();
  }

  LabRun get run => _run;
  bool get isSaving => _isSaving;

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    super.dispose();
  }

  /// Restores running timers from persisted state on app restart
  void _restoreTimers() {
    final updatedSteps = <ProcedureStep>[];
    bool needsUpdate = false;

    for (int i = 0; i < _run.steps.length; i++) {
      final step = _run.steps[i];
      if (step.kind == StepKind.timer) {
        // Initialize remainingSeconds if not set
        if (step.remainingSeconds == null && step.timerSeconds != null) {
          final updatedStep = ProcedureStep(
            id: step.id,
            kind: step.kind,
            title: step.title,
            description: step.description,
            order: step.order,
            status: step.status,
            items: step.items,
            timerSeconds: step.timerSeconds,
            remainingSeconds: step.timerSeconds,
            timerState: TimerState.idle,
            timerStartedAt: null,
            unit: step.unit,
            value: step.value,
            ingredientSectionId: step.ingredientSectionId,
            ingredientSectionLabel: step.ingredientSectionLabel,
          );
          updatedSteps.add(updatedStep);
          needsUpdate = true;
          continue;
        }

        // Restore running timer
        if (step.timerState == TimerState.running &&
            step.remainingSeconds != null &&
            step.remainingSeconds! > 0 &&
            step.timerStartedAt != null) {
          // Calculate elapsed time since start
          final elapsed = DateTime.now().difference(step.timerStartedAt!);
          final remaining = step.remainingSeconds! - elapsed.inSeconds;
          if (remaining > 0) {
            // Resume timer with remaining time
            _startTimerInternal(step.id, remaining);
            updatedSteps.add(step);
            continue;
          } else {
            // Timer should have finished, mark it as finished
            _markTimerFinished(step.id);
            return; // _markTimerFinished will update the run and notify
          }
        }
      }
      updatedSteps.add(step);
    }

    if (needsUpdate) {
      _run = LabRun(
        id: _run.id,
        createdAt: _run.createdAt,
        recipe: _run.recipe,
        batchCode: _run.batchCode,
        steps: updatedSteps,
        notes: _run.notes,
        archived: _run.archived,
        finishedAt: _run.finishedAt,
        formula: _run.formula,
        templateId: _run.templateId,
        ingredientChecks: _run.ingredientChecks,
      );
      notifyListeners();
    }
  }

  /// Toggles a checklist item's done state.
  /// Triggers debounced save.
  void toggleChecklistItem(String stepId, String itemId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.items == null) return;

    final itemIndex = step.items!.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) return;

    // Toggle the item
    final updatedItems = List<ChecklistItem>.from(step.items!);
    updatedItems[itemIndex] = ChecklistItem(
      id: updatedItems[itemIndex].id,
      label: updatedItems[itemIndex].label,
      done: !updatedItems[itemIndex].done,
    );

    // Update step with new items
    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: step.status,
      items: updatedItems,
      timerSeconds: step.timerSeconds,
      remainingSeconds: step.remainingSeconds,
      timerState: step.timerState,
      timerStartedAt: step.timerStartedAt,
      unit: step.unit,
      value: step.value,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    // Update all steps
    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Opens ingredients view for a specific section, tracking the source step.
  /// This is called when user taps "Ingredients → <section>" from a step card.
  void openIngredientsForSection(String sectionId, String? sourceStepId) {
    _activeIngredientSectionId = sectionId;
    _sourceStepId = sourceStepId;
    Log.d(
      'RunController',
      'Opened ingredients for section: $sectionId (from step: $sourceStepId)',
    );
    notifyListeners();
  }

  /// Clears the navigation context (e.g., when user manually opens ingredients tab).
  void clearIngredientsContext() {
    _activeIngredientSectionId = null;
    _sourceStepId = null;
    notifyListeners();
  }

  /// Toggles an ingredient check state.
  /// Key format: "phase:<phaseId>:<itemId>" for cream, "soap:oils:<oilId>" for soap oils
  /// Triggers debounced save.
  /// Also checks if ANY section is complete and auto-completes the corresponding step if needed.
  void toggleIngredientCheck(String key) {
    final updatedChecks = Map<String, bool>.from(_run.ingredientChecks);
    updatedChecks[key] = !(updatedChecks[key] ?? false);

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: _run.steps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: updatedChecks,
    );

    Log.d('RunController', 'Ingredient checked: $key');

    // Check ALL sections for completion (not just the active one)
    // This ensures auto-return works for any section, regardless of how user navigated to it
    _checkAllSectionsForCompletion();

    notifyListeners();
    _debouncedSave();
  }

  /// Checks ALL ingredient sections for completion and auto-completes
  /// the corresponding steps if all ingredients in a section are checked.
  /// This works for any section (Phase A/B/C, soap oils, etc.), not just the active one.
  void _checkAllSectionsForCompletion() {
    // Get all unique section IDs from steps
    final sectionIds = <String>{};
    for (final step in _run.steps) {
      if (step.ingredientSectionId != null) {
        sectionIds.add(step.ingredientSectionId!);
      }
    }

    if (sectionIds.isEmpty) {
      return; // No sections to check
    }

    // Check each section for completion
    for (final sectionId in sectionIds) {
      final sectionKeys = IngredientSectionHelper.getSectionKeys(_run, sectionId);

      if (sectionKeys.isEmpty) {
        continue; // Skip sections with no checkable items
      }

      // Check if all keys for this section are checked
      final allChecked = sectionKeys.every(
        (key) => _run.ingredientChecks[key] == true,
      );

      if (allChecked) {
        // Find the step that references this section
        final step = _run.steps.firstWhere(
          (s) => s.ingredientSectionId == sectionId,
          orElse: () => _run.steps.first, // Fallback (shouldn't happen)
        );

        // Only auto-complete if the step is not already done
        if (step.status != StepStatus.done) {
          // Auto-complete the step
          setStepStatus(step.id, StepStatus.done);
          Log.d(
            'RunController',
            'Section complete: $sectionId -> auto-done step ${step.id}',
          );

          // Clear active context if this was the active section
          if (_activeIngredientSectionId == sectionId) {
            _activeIngredientSectionId = null;
            _sourceStepId = null;
          }

          // Notify that we should navigate back to steps and focus next step
          notifyListeners();

          // Call the completion callback to trigger navigation
          onSectionCompleted?.call(sectionId, step.id);

          // Only process one completion per toggle to avoid multiple navigations
          break;
        }
      }
    }
  }

  /// Gets the next step ID after the given step ID.
  /// Returns null if there's no next step.
  String? getNextStepId(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0 || stepIndex >= _run.steps.length - 1) {
      return null;
    }

    // Find next non-section step
    for (int i = stepIndex + 1; i < _run.steps.length; i++) {
      if (_run.steps[i].kind != StepKind.section) {
        return _run.steps[i].id;
      }
    }

    return null;
  }

  /// Sets the numeric input value for a step.
  /// Triggers debounced save.
  void setInputNumber(String stepId, num? value) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: step.status,
      items: step.items,
      timerSeconds: step.timerSeconds,
      remainingSeconds: step.remainingSeconds,
      timerState: step.timerState,
      timerStartedAt: step.timerStartedAt,
      unit: step.unit,
      value: value,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Sets the status of a step.
  /// Triggers debounced save.
  void setStepStatus(String stepId, StepStatus status) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: status,
      items: step.items,
      timerSeconds: step.timerSeconds,
      remainingSeconds: step.remainingSeconds,
      timerState: step.timerState,
      timerStartedAt: step.timerStartedAt,
      unit: step.unit,
      value: step.value,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Updates the run's notes.
  /// Triggers debounced save.
  void setRunNotes(String? notes) {
    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: _run.steps,
      notes: notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Updates a step (used for complex step updates from widgets).
  /// Triggers debounced save.
  void updateStep(int index, ProcedureStep updatedStep) {
    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[index] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Updates the entire run (used for formula updates).
  /// Triggers debounced save.
  void updateRun(LabRun updatedRun) {
    _run = updatedRun;
    notifyListeners();
    _debouncedSave();
  }

  /// Resets all progress: checklist items unchecked, inputs cleared, notes removed.
  /// Saves immediately (no debounce).
  void resetProgress() {
    final resetSteps = _run.steps.map((step) {
      switch (step.kind) {
        case StepKind.checklist:
          final resetItems = step.items?.map((item) {
            return ChecklistItem(id: item.id, label: item.label, done: false);
          }).toList();
          return ProcedureStep(
            id: step.id,
            kind: step.kind,
            title: step.title,
            description: step.description,
            order: step.order,
            status: StepStatus.todo,
            items: resetItems,
            ingredientSectionId: step.ingredientSectionId,
            ingredientSectionLabel: step.ingredientSectionLabel,
          );
        case StepKind.inputNumber:
          return ProcedureStep(
            id: step.id,
            kind: step.kind,
            title: step.title,
            description: step.description,
            order: step.order,
            status: StepStatus.todo,
            unit: step.unit,
            value: null,
            ingredientSectionId: step.ingredientSectionId,
            ingredientSectionLabel: step.ingredientSectionLabel,
          );
        case StepKind.note:
          return ProcedureStep(
            id: step.id,
            kind: step.kind,
            title: step.title,
            description: null,
            order: step.order,
            status: StepStatus.todo,
            ingredientSectionId: step.ingredientSectionId,
            ingredientSectionLabel: step.ingredientSectionLabel,
          );
        case StepKind.timer:
          // Stop timer if running
          _activeTimers[step.id]?.cancel();
          _activeTimers.remove(step.id);
          return ProcedureStep(
            id: step.id,
            kind: step.kind,
            title: step.title,
            description: step.description,
            order: step.order,
            status: StepStatus.todo,
            timerSeconds: step.timerSeconds,
            remainingSeconds: step.timerSeconds,
            timerState: TimerState.idle,
            timerStartedAt: null,
            ingredientSectionId: step.ingredientSectionId,
            ingredientSectionLabel: step.ingredientSectionLabel,
          );
        default:
          return ProcedureStep(
            id: step.id,
            kind: step.kind,
            title: step.title,
            description: step.description,
            order: step.order,
            status: StepStatus.todo,
            timerSeconds: step.timerSeconds,
            remainingSeconds: step.remainingSeconds,
            timerState: step.timerState,
            timerStartedAt: step.timerStartedAt,
            ingredientSectionId: step.ingredientSectionId,
            ingredientSectionLabel: step.ingredientSectionLabel,
          );
      }
    }).toList();

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: resetSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    // Save immediately for reset (no debounce)
    _saveImmediately();
  }

  /// Saves immediately (no debounce). Used for manual saves and reset.
  Future<void> saveImmediately() async {
    await _saveImmediately();
  }

  /// Debounced save - only triggers on user actions, never on timer ticks.
  /// Waits 800ms after last action before saving to avoid excessive I/O.
  /// This ensures saves happen after user finishes typing/clicking, not during.
  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _saveImmediately();
    });
  }

  /// Internal save method.
  Future<void> _saveImmediately() async {
    _saveDebounceTimer?.cancel();
    _isSaving = true;
    notifyListeners();

    Log.d('RunController', 'Save triggered for run: ${_run.id}');
    await _repository.save(_run);
    Log.d('RunController', 'Run saved: ${_run.id}');

    _isSaving = false;
    notifyListeners();
  }

  /// Starts a timer for a timer step.
  /// Triggers save.
  void startTimer(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer || step.timerSeconds == null) return;

    final remaining = step.remainingSeconds ?? step.timerSeconds!;
    if (remaining <= 0) return;

    _startTimerInternal(stepId, remaining);
    _updateTimerStep(
      stepIndex,
      step,
      remaining,
      TimerState.running,
      DateTime.now(),
    );
    _debouncedSave();
  }

  /// Internal method to start timer tick
  void _startTimerInternal(String stepId, int remainingSeconds) {
    _activeTimers[stepId]?.cancel();
    _activeTimers[stepId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
      if (stepIndex < 0) {
        timer.cancel();
        _activeTimers.remove(stepId);
        return;
      }

      final step = _run.steps[stepIndex];
      final currentRemaining = step.remainingSeconds ?? 0;

      if (currentRemaining <= 1) {
        // Timer finished
        timer.cancel();
        _activeTimers.remove(stepId);
        _markTimerFinished(stepId);
      } else {
        // Update remaining seconds (no save on tick)
        _updateTimerStep(
          stepIndex,
          step,
          currentRemaining - 1,
          TimerState.running,
          step.timerStartedAt,
        );
        notifyListeners(); // Update UI only
      }
    });
  }

  /// Pauses a running timer.
  /// Triggers save.
  void pauseTimer(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer) return;

    _activeTimers[stepId]?.cancel();
    _activeTimers.remove(stepId);

    _updateTimerStep(
      stepIndex,
      step,
      step.remainingSeconds,
      TimerState.paused,
      step.timerStartedAt,
    );
    _debouncedSave();
  }

  /// Resets a timer to its initial state.
  /// Triggers save.
  void resetTimer(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer || step.timerSeconds == null) return;

    _activeTimers[stepId]?.cancel();
    _activeTimers.remove(stepId);

    _updateTimerStep(stepIndex, step, step.timerSeconds, TimerState.idle, null);
    _debouncedSave();
  }

  /// Marks a timer step as done.
  /// Triggers save.
  void markTimerDone(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer) return;

    _activeTimers[stepId]?.cancel();
    _activeTimers.remove(stepId);

    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: StepStatus.done,
      timerSeconds: step.timerSeconds,
      remainingSeconds: step.remainingSeconds,
      timerState: step.timerState,
      timerStartedAt: step.timerStartedAt,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Toggles timer step status between done and todo.
  /// Triggers save.
  void toggleTimerStatus(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer) return;

    _activeTimers[stepId]?.cancel();
    _activeTimers.remove(stepId);

    final newStatus = step.status == StepStatus.done
        ? StepStatus.todo
        : StepStatus.done;
    final newTimerState = newStatus == StepStatus.done
        ? (step.timerState == TimerState.finished
              ? TimerState.finished
              : TimerState.idle)
        : TimerState.idle;

    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: newStatus,
      timerSeconds: step.timerSeconds,
      remainingSeconds: newStatus == StepStatus.todo
          ? step.timerSeconds
          : step.remainingSeconds,
      timerState: newTimerState,
      timerStartedAt: newStatus == StepStatus.todo ? null : step.timerStartedAt,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _debouncedSave();
  }

  /// Skips a timer step.
  /// Sets status to done, timerState to finished, remainingSeconds to 0.
  /// Triggers save once (no tick saves).
  void skipTimer(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer) return;

    _activeTimers[stepId]?.cancel();
    _activeTimers.remove(stepId);

    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: StepStatus.done,
      timerSeconds: step.timerSeconds,
      remainingSeconds: 0,
      timerState: TimerState.finished,
      timerStartedAt: step.timerStartedAt,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
    _saveImmediately(); // Save once, no debounce
  }

  /// Marks timer as finished when it reaches 0.
  /// Triggers save and callback for SnackBar.
  void _markTimerFinished(String stepId) {
    final stepIndex = _run.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex < 0) return;

    final step = _run.steps[stepIndex];
    if (step.kind != StepKind.timer) return;

    _updateTimerStep(
      stepIndex,
      step,
      0,
      TimerState.finished,
      step.timerStartedAt,
    );
    _saveImmediately(); // Save immediately when timer finishes

    // Trigger callback for SnackBar
    if (onTimerFinished != null) {
      onTimerFinished!(stepId, step.title);
    }
  }

  /// Finishes the run: sets finishedAt, archived = true, and saves.
  /// Returns the updated run.
  /// Prevents overwriting finishedAt if run is already archived.
  Future<void> finishRun() async {
    // Guard: Don't overwrite finishedAt if run is already archived
    if (_run.archived && _run.finishedAt != null) {
      return;
    }

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: _run.steps,
      notes: _run.notes,
      archived: true,
      finishedAt: DateTime.now(),
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );
    Log.d('RunController', 'Run finished -> archived: ${_run.id}');

    notifyListeners();
    await _saveImmediately();
  }

  /// Helper to update timer step state
  void _updateTimerStep(
    int stepIndex,
    ProcedureStep step,
    int? remainingSeconds,
    TimerState? timerState,
    DateTime? startedAt,
  ) {
    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: step.status,
      items: step.items,
      timerSeconds: step.timerSeconds,
      remainingSeconds: remainingSeconds,
      timerState: timerState,
      timerStartedAt: startedAt,
      unit: step.unit,
      value: step.value,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );

    final updatedSteps = List<ProcedureStep>.from(_run.steps);
    updatedSteps[stepIndex] = updatedStep;

    _run = LabRun(
      id: _run.id,
      createdAt: _run.createdAt,
      recipe: _run.recipe,
      batchCode: _run.batchCode,
      steps: updatedSteps,
      notes: _run.notes,
      archived: _run.archived,
      finishedAt: _run.finishedAt,
      formula: _run.formula,
      templateId: _run.templateId,
      ingredientChecks: _run.ingredientChecks,
    );

    notifyListeners();
  }
}
