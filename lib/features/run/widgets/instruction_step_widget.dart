import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';

class InstructionStepWidget extends StatelessWidget {
  final ProcedureStep step;
  final ValueChanged<StepStatus> onStatusChanged;
  final VoidCallback? onNavigateToIngredients;

  const InstructionStepWidget({
    super.key,
    required this.step,
    required this.onStatusChanged,
    this.onNavigateToIngredients,
  });

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
                      color: step.status == StepStatus.done
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (step.status == StepStatus.done) {
                      onStatusChanged(StepStatus.todo);
                    } else if (step.status == StepStatus.todo) {
                      onStatusChanged(StepStatus.done);
                    }
                  },
                  child: _buildStatusChip(context),
                ),
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
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String label;
    switch (step.status) {
      case StepStatus.todo:
        color = Colors.grey;
        label = 'TODO';
        break;
      case StepStatus.doing:
        color = Colors.blue;
        label = 'DOING';
        break;
      case StepStatus.done:
        color = Colors.green;
        label = 'DONE';
        break;
      case StepStatus.skipped:
        color = Colors.orange;
        label = 'SKIPPED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (step.ingredientSectionId != null && onNavigateToIngredients != null)
          _buildIngredientChip(context),
        if (step.status != StepStatus.doing)
          FilledButton.icon(
            onPressed: () => onStatusChanged(StepStatus.doing),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        if (step.status == StepStatus.doing)
          FilledButton.icon(
            onPressed: () => onStatusChanged(StepStatus.done),
            icon: const Icon(Icons.check),
            label: const Text('Complete'),
          ),
        if (step.status != StepStatus.skipped)
          OutlinedButton.icon(
            onPressed: () => onStatusChanged(StepStatus.skipped),
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip'),
          ),
        if (step.status != StepStatus.todo)
          OutlinedButton.icon(
            onPressed: () => onStatusChanged(StepStatus.todo),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
      ],
    );
  }

  Widget _buildIngredientChip(BuildContext context) {
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
        child: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Ingredients → $label',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
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
