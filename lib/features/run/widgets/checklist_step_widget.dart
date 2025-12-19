import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';
import '../../../domain/checklist_item.dart';

class ChecklistStepWidget extends StatelessWidget {
  final ProcedureStep step;
  final ValueChanged<ProcedureStep> onStepUpdated;
  final VoidCallback? onNavigateToIngredients;

  const ChecklistStepWidget({
    super.key,
    required this.step,
    required this.onStepUpdated,
    this.onNavigateToIngredients,
  });

  void _toggleItem(int itemIndex) {
    if (step.items == null) return;
    final updatedItems = List<ChecklistItem>.from(step.items!);
    updatedItems[itemIndex] = ChecklistItem(
      id: updatedItems[itemIndex].id,
      label: updatedItems[itemIndex].label,
      done: !updatedItems[itemIndex].done,
    );
    final allDone = updatedItems.every((item) => item.done);
    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: allDone ? StepStatus.done : StepStatus.doing,
      items: updatedItems,
      timerSeconds: step.timerSeconds,
      remainingSeconds: step.remainingSeconds,
      timerState: step.timerState,
      timerStartedAt: step.timerStartedAt,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );
    onStepUpdated(updatedStep);
  }

  void _resetItem(int itemIndex) {
    if (step.items == null) return;
    final updatedItems = List<ChecklistItem>.from(step.items!);
    updatedItems[itemIndex] = ChecklistItem(
      id: updatedItems[itemIndex].id,
      label: updatedItems[itemIndex].label,
      done: false,
    );
    final allDone = updatedItems.every((item) => item.done);
    final updatedStep = ProcedureStep(
      id: step.id,
      kind: step.kind,
      title: step.title,
      description: step.description,
      order: step.order,
      status: allDone ? StepStatus.done : StepStatus.doing,
      items: updatedItems,
      timerSeconds: step.timerSeconds,
      remainingSeconds: step.remainingSeconds,
      timerState: step.timerState,
      timerStartedAt: step.timerStartedAt,
      ingredientSectionId: step.ingredientSectionId,
      ingredientSectionLabel: step.ingredientSectionLabel,
    );
    onStepUpdated(updatedStep);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: step.status == StepStatus.done ? 1 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      decoration: step.status == StepStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (step.status == StepStatus.done)
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            if (step.description != null && step.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                step.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (step.ingredientSectionId != null &&
                onNavigateToIngredients != null) ...[
              const SizedBox(height: 12),
              _buildIngredientLink(context),
            ],
            if (step.items != null && step.items!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...step.items!.asMap().entries.map((entry) {
                final item = entry.value;
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item.done,
                        onChanged: (_) => _toggleItem(index),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onLongPress: item.done
                              ? () => _resetItem(index)
                              : null,
                          child: Text(
                            item.label,
                            style: TextStyle(
                              decoration: item.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.done
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (item.done)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () => _resetItem(index),
                          tooltip: 'Reset',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientLink(BuildContext context) {
    final label = step.ingredientSectionLabel ?? 'Ingredients';
    return InkWell(
      onTap: onNavigateToIngredients,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingredients → $label',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
