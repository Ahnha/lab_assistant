import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';

class TimerStepWidget extends StatelessWidget {
  final ProcedureStep step;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onReset;
  final VoidCallback? onMarkDone;
  final VoidCallback? onSkip;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onNavigateToIngredients;

  const TimerStepWidget({
    super.key,
    required this.step,
    this.onStart,
    this.onPause,
    this.onReset,
    this.onMarkDone,
    this.onSkip,
    this.onToggleStatus,
    this.onNavigateToIngredients,
  });

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = step.remainingSeconds ?? step.timerSeconds ?? 0;
    final isRunning = step.timerState == TimerState.running;
    final isFinished = step.timerState == TimerState.finished;
    final canMarkDone = isFinished || step.status == StepStatus.done;

    return Card(
      elevation: step.status == StepStatus.done ? 1 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.title, style: Theme.of(context).textTheme.titleLarge),
            if (step.description != null && step.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                step.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: Text(
                _formatTime(remainingSeconds),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (step.ingredientSectionId != null &&
                    onNavigateToIngredients != null)
                  _buildIngredientChip(context),
                if (!isRunning && remainingSeconds > 0)
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                if (isRunning) ...[
                  FilledButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                ],
                if (remainingSeconds > 0 || step.timerState != TimerState.idle)
                  OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                if (canMarkDone && step.status != StepStatus.done)
                  FilledButton.icon(
                    onPressed: onMarkDone,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Done'),
                  ),
                if (step.status == StepStatus.done && onToggleStatus != null)
                  OutlinedButton.icon(
                    onPressed: onToggleStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Mark Todo'),
                  ),
                if (step.status != StepStatus.done &&
                    step.status != StepStatus.skipped)
                  OutlinedButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                  ),
              ],
            ),
          ],
        ),
      ),
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
