import 'package:flutter/material.dart';
import '../../../domain/step_status.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_kind.dart';

/// A subtle progress indicator showing completed steps out of total.
/// Displays as "X of Y complete" with a thin progress bar.
class StepProgressIndicator extends StatelessWidget {
  final List<ProcedureStep> steps;

  const StepProgressIndicator({super.key, required this.steps});

  int get _completedCount {
    return steps.where((step) => step.status == StepStatus.done).length;
  }

  int get _totalCount {
    // Exclude section steps from count
    return steps.where((step) => step.kind != StepKind.section).length;
  }

  double get _progress {
    if (_totalCount == 0) return 0.0;
    return _completedCount / _totalCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalCount;
    final completed = _completedCount;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completed of $total complete',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_progress * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
