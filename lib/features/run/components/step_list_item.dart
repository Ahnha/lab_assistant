import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';
import '../../../domain/step_kind.dart';
import '../../../ui/spacing.dart';

/// A compact step list item with iOS-like styling.
/// Shows status icon, title, and optional metadata.
class StepListItem extends StatelessWidget {
  final ProcedureStep step;
  final bool isCurrent;
  final VoidCallback? onTap;

  const StepListItem({
    super.key,
    required this.step,
    this.isCurrent = false,
    this.onTap,
  });

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);
    final size = 20.0;

    switch (step.status) {
      case StepStatus.done:
        return Icon(
          Icons.check_circle,
          size: size,
          color: theme.colorScheme.primary,
        );
      case StepStatus.doing:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        );
      case StepStatus.skipped:
        return Icon(
          Icons.remove_circle_outline,
          size: size,
          color: theme.colorScheme.onSurfaceVariant,
        );
      case StepStatus.todo:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        );
    }
  }

  String? _getMetadata() {
    if (step.kind == StepKind.timer && step.timerSeconds != null) {
      final minutes = (step.timerSeconds! / 60).round();
      if (minutes > 0) {
        return '${minutes}m';
      }
    }
    if (step.kind == StepKind.inputNumber && step.value != null && step.unit != null) {
      return '${step.value} ${step.unit}';
    }
    if (step.kind == StepKind.checklist && step.items != null) {
      final doneCount = step.items!.where((item) => item.done).length;
      final totalCount = step.items!.length;
      if (totalCount > 0) {
        return '$doneCount/$totalCount';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _getMetadata();
    final isDone = step.status == StepStatus.done;
    final isSection = step.kind == StepKind.section;

    // Section steps get special styling
    if (isSection) {
      return Padding(
        padding: EdgeInsets.only(
          top: LabSpacing.gapLg(),
          bottom: LabSpacing.gapSm(),
        ),
        child: Text(
          step.title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: LabSpacing.gapLg(),
          vertical: LabSpacing.gapMd(),
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Status icon
            SizedBox(
              width: 24,
              child: _buildStatusIcon(context),
            ),
            SizedBox(width: LabSpacing.gapMd()),
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.w500,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: isDone
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (step.description != null &&
                      step.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Metadata
            if (metadata != null) ...[
              SizedBox(width: LabSpacing.gapSm()),
              Text(
                metadata,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            // Done indicator
            if (isDone && metadata == null) ...[
              SizedBox(width: LabSpacing.gapSm()),
              Text(
                'Done',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
