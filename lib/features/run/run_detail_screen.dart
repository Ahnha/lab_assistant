import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../domain/lab_run.dart';
import '../../domain/procedure_step.dart';
import '../../domain/step_kind.dart';
import '../../domain/recipe_kind.dart';
import '../../data/lab_run_repository.dart';
import '../../data/app_settings.dart';
import '../../utils/date_formatter.dart';
import '../../app/log.dart';
import '../../app/ui_tokens.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/secondary_button.dart';
import 'run_controller.dart';
import 'widgets/instruction_step_widget.dart';
import 'widgets/checklist_step_widget.dart';
import 'widgets/timer_step_widget.dart';
import 'widgets/input_number_step_widget.dart';
import 'widgets/note_step_widget.dart';
import 'widgets/section_step_widget.dart';
import 'widgets/ingredients_view.dart';

class RunDetailScreen extends StatefulWidget {
  final LabRun run;
  final ValueChanged<LabRun>? onRunUpdated;
  final VoidCallback? onRunDeleted;
  final bool isEmbedded;

  const RunDetailScreen({
    super.key,
    required this.run,
    this.onRunUpdated,
    this.onRunDeleted,
    this.isEmbedded = false,
  });

  @override
  State<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  late RunController _controller;
  final LabRunRepository _repository = LabRunRepository();
  int _selectedTab = 0;
  final GlobalKey<IngredientsViewState> _ingredientsViewKey = GlobalKey();
  final ScrollController _ingredientsScrollController = ScrollController();
  final ScrollController _stepsScrollController = ScrollController();
  final Map<String, GlobalKey> _stepKeys = {};
  bool _labModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = RunController(widget.run);
    _controller.addListener(_onControllerChanged);
    _controller.onTimerFinished = _onTimerFinished;
    _controller.onSectionCompleted = _onSectionCompleted;
    _loadLabModeSetting();
    _initializeStepKeys();
  }

  void _initializeStepKeys() {
    for (final step in widget.run.steps) {
      _stepKeys[step.id] = GlobalKey();
    }
  }

  void _onTimerFinished(String stepId, String stepTitle) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timer finished: $stepTitle'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadLabModeSetting() async {
    final enabled = await AppSettings.isLabModeEnabled();
    if (mounted) {
      setState(() {
        _labModeEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _ingredientsScrollController.dispose();
    _stepsScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Note: Auto-navigation is now handled by _onSectionCompleted callback
    // This method just updates the UI state
    setState(() {});
  }

  bool _autoReturnEnabled =
      true; // Default to true, will be loaded from settings
  bool _userChoseToStay = false; // Track if user tapped "Stay"

  Future<void> _onSectionCompleted(String sectionId, String stepId) async {
    // Load auto-return setting
    _autoReturnEnabled = await AppSettings.isAutoReturnEnabled();

    if (!mounted) return;

    if (_autoReturnEnabled) {
      // Reset stay flag
      _userChoseToStay = false;

      // Show snackbar with "Back to steps" and "Stay" options
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars(); // Clear any existing snackbars

      final snackBar = SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Section complete! Return to steps?')),
          ],
        ),
        duration: const Duration(milliseconds: 3000),
        action: SnackBarAction(
          label: 'Stay',
          textColor: Colors.white,
          onPressed: () {
            // User chose to stay, do not navigate
            _userChoseToStay = true;
            scaffoldMessenger.hideCurrentSnackBar();
          },
        ),
      );

      scaffoldMessenger.showSnackBar(snackBar);

      // Auto-navigate after delay if user doesn't tap "Stay"
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !_userChoseToStay) {
          scaffoldMessenger.hideCurrentSnackBar();
          _navigateBackToSteps(stepId);
        }
      });
    } else {
      // Auto-return disabled, just show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Section complete ✅'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateBackToSteps(String stepId) {
    final nextStepId = _controller.getNextStepId(stepId);
    setState(() {
      _selectedTab = 0;
    });
    // Scroll to next step after a frame
    if (nextStepId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToStep(nextStepId);
      });
    }
  }

  void _navigateToIngredientSection(String? sectionId, String stepId) {
    if (sectionId == null) return;

    // Set navigation context in controller
    _controller.openIngredientsForSection(sectionId, stepId);

    // Switch to Ingredients tab
    setState(() {
      _selectedTab = 1;
    });

    // Wait for the tab to switch, then scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ingredientsState = _ingredientsViewKey.currentState;
      ingredientsState?.scrollToSection(sectionId);
    });
  }

  void _scrollToStep(String stepId) {
    final key = _stepKeys[stepId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to show step near top
      );
    }
  }

  Future<void> _saveRun({bool showMessage = false}) async {
    await _controller.saveImmediately();
    // Notify parent of update in embedded mode after save
    if (widget.isEmbedded && widget.onRunUpdated != null) {
      // Wait a frame to ensure the controller has finished updating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onRunUpdated!(_controller.run);
        }
      });
    }
    if (mounted && showMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  void _showResetProgressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'This will reset all steps to their initial state. Checklist items will be unchecked, input values cleared, and notes removed. This action cannot be undone.',
        ),
        actions: [
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PrimaryButton(
            label: 'Reset',
            onPressed: () {
              Navigator.of(context).pop();
              _controller.resetProgress();
            },
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Future<void> _finishRun() async {
    await _controller.finishRun();
    if (!mounted) return;

    if (widget.isEmbedded && widget.onRunUpdated != null) {
      widget.onRunUpdated!(_controller.run);
    } else {
      // Navigate back to Inbox
      Navigator.of(context).pop();
    }
  }

  Future<void> _exportRun() async {
    try {
      final run = _controller.run;
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(run.toJson());

      await Clipboard.setData(ClipboardData(text: formattedJson));
      Log.d('RunDetailScreen', 'Exported run to clipboard: ${run.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Run JSON copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Log.d('RunDetailScreen', 'Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteRunDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Run'),
        content: const Text(
          'Are you sure you want to delete this run? This action cannot be undone.',
        ),
        actions: [
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PrimaryButton(
            label: 'Delete',
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              Log.d('RunDetailScreen', 'Deleting run: ${_controller.run.id}');
              if (widget.isEmbedded && widget.onRunDeleted != null) {
                // In embedded mode, let the parent handle deletion
                widget.onRunDeleted!();
              } else {
                // In standalone mode, delete and pop
                await _repository.delete(_controller.run.id);
                if (!mounted) return;
                navigator.pop();
              }
            },
            backgroundColor: Theme.of(context).colorScheme.error,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final run = _controller.run;
    Widget scaffold = Scaffold(
      appBar: AppBar(
        title: Text(run.recipe.name),
        centerTitle: true,
        actions: [
          if (_controller.isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveRun(showMessage: true),
              tooltip: 'Save',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _showResetProgressDialog();
              } else if (value == 'finish') {
                _finishRun();
              } else if (value == 'export') {
                _exportRun();
              } else if (value == 'delete') {
                _showDeleteRunDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: UITokens.spacingS),
                    Text('Reset progress'),
                  ],
                ),
              ),
              if (!run.archived)
                const PopupMenuItem(
                  value: 'finish',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: UITokens.spacingS),
                      Text('Finish Run'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: UITokens.spacingS),
                    Text('Export JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete run', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              _labModeEnabled ? UITokens.spacingXL : UITokens.spacingL,
            ),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.recipe.kind.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatDateTime(run.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  '${run.completedSteps}/${run.totalSteps}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(
              _labModeEnabled ? UITokens.spacingXL : UITokens.spacingL,
            ),
            child: Column(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Steps')),
                    ButtonSegment(value: 1, label: Text('Ingredients')),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (Set<int> newSelection) {
                    final newTab = newSelection.first;
                    // Clear navigation context if user manually switches to ingredients
                    if (newTab == 1 && _selectedTab == 0) {
                      _controller.clearIngredientsContext();
                    }
                    setState(() {
                      _selectedTab = newTab;
                    });
                  },
                ),
                if (run.completedSteps == run.totalSteps &&
                    run.totalSteps > 0 &&
                    !run.archived) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Finish Run',
                    onPressed: _finishRun,
                    isFullWidth: true,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? ListView.builder(
                    controller: _stepsScrollController,
                    padding: EdgeInsets.all(_labModeEnabled ? 20 : 16),
                    itemCount: run.steps.length,
                    itemBuilder: (context, index) {
                      final step = run.steps[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: _labModeEnabled ? 20 : 16,
                        ),
                        child: _buildStepWidget(step, index),
                      );
                    },
                  )
                : IngredientsView(
                    key: _ingredientsViewKey,
                    run: run,
                    onRunUpdated: _controller.updateRun,
                    scrollController: _ingredientsScrollController,
                    onIngredientCheckToggled: (key) {
                      _controller.toggleIngredientCheck(key);
                    },
                  ),
          ),
        ],
      ),
    );

    // Wrap with PopScope only in standalone mode (not embedded)
    if (widget.isEmbedded) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(run);
        }
      },
      child: scaffold,
    );
  }

  Widget _buildStepWidget(ProcedureStep step, int index) {
    final stepKey = _stepKeys[step.id] ??= GlobalKey();
    Widget stepWidget;

    switch (step.kind) {
      case StepKind.instruction:
        stepWidget = InstructionStepWidget(
          step: step,
          onStatusChanged: (status) {
            _controller.setStepStatus(step.id, status);
          },
          onNavigateToIngredients: step.ingredientSectionId != null
              ? () => _navigateToIngredientSection(
                  step.ingredientSectionId,
                  step.id,
                )
              : null,
        );
        break;
      case StepKind.checklist:
        stepWidget = ChecklistStepWidget(
          step: step,
          onStepUpdated: (updated) {
            // Widget handles item toggling and status updates
            final fullUpdated = ProcedureStep(
              id: updated.id,
              kind: updated.kind,
              title: updated.title,
              description: updated.description,
              order: updated.order,
              status: updated.status,
              items: updated.items,
              timerSeconds: step.timerSeconds,
              remainingSeconds: step.remainingSeconds,
              timerState: step.timerState,
              timerStartedAt: step.timerStartedAt,
              ingredientSectionId: step.ingredientSectionId,
              ingredientSectionLabel: step.ingredientSectionLabel,
            );
            _controller.updateStep(index, fullUpdated);
          },
          onNavigateToIngredients: step.ingredientSectionId != null
              ? () => _navigateToIngredientSection(
                  step.ingredientSectionId,
                  step.id,
                )
              : null,
        );
        break;
      case StepKind.timer:
        stepWidget = TimerStepWidget(
          step: step,
          onStart: () => _controller.startTimer(step.id),
          onPause: () => _controller.pauseTimer(step.id),
          onReset: () => _controller.resetTimer(step.id),
          onMarkDone: () => _controller.markTimerDone(step.id),
          onSkip: () => _controller.skipTimer(step.id),
          onToggleStatus: () => _controller.toggleTimerStatus(step.id),
          onNavigateToIngredients: step.ingredientSectionId != null
              ? () => _navigateToIngredientSection(
                  step.ingredientSectionId,
                  step.id,
                )
              : null,
        );
        break;
      case StepKind.inputNumber:
        stepWidget = InputNumberStepWidget(
          step: step,
          onStepUpdated: (updated) {
            _controller.setInputNumber(step.id, updated.value);
            // Also update status if value changed
            if (updated.status != step.status) {
              _controller.setStepStatus(step.id, updated.status);
            }
          },
          onNavigateToIngredients: step.ingredientSectionId != null
              ? () => _navigateToIngredientSection(
                  step.ingredientSectionId,
                  step.id,
                )
              : null,
        );
        break;
      case StepKind.note:
        stepWidget = NoteStepWidget(
          step: step,
          onStepUpdated: (updated) {
            final fullUpdated = ProcedureStep(
              id: updated.id,
              kind: updated.kind,
              title: updated.title,
              description: updated.description,
              order: updated.order,
              status: updated.status,
              timerSeconds: step.timerSeconds,
              remainingSeconds: step.remainingSeconds,
              timerState: step.timerState,
              timerStartedAt: step.timerStartedAt,
              ingredientSectionId: step.ingredientSectionId,
              ingredientSectionLabel: step.ingredientSectionLabel,
            );
            _controller.updateStep(index, fullUpdated);
          },
          onNavigateToIngredients: step.ingredientSectionId != null
              ? () => _navigateToIngredientSection(
                  step.ingredientSectionId,
                  step.id,
                )
              : null,
        );
        break;
      case StepKind.section:
        stepWidget = SectionStepWidget(step: step);
        break;
    }

    return KeyedSubtree(key: stepKey, child: stepWidget);
  }
}
