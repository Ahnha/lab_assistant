import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';
import '../../../domain/step_kind.dart';
import '../../../ui/widgets/ss_card.dart';
import '../../../ui/spacing.dart';
import 'step_list_item.dart';
import 'step_progress_indicator.dart';

/// A grouped list of steps in a single card with dividers.
/// Shows progress indicator at top, then all steps as list items.
class StepListView extends StatelessWidget {
  final List<ProcedureStep> steps;
  final ValueChanged<ProcedureStep>? onStepTap;
  final String? currentStepId;

  const StepListView({
    super.key,
    required this.steps,
    this.onStepTap,
    this.currentStepId,
  });

  ProcedureStep? _getCurrentStep() {
    if (steps.isEmpty) return null;
    
    if (currentStepId != null) {
      try {
        return steps.firstWhere((step) => step.id == currentStepId);
      } catch (e) {
        return null;
      }
    }
    
    // Find first step with status "doing"
    try {
      return steps.firstWhere(
        (step) => step.status == StepStatus.doing && step.kind != StepKind.section,
      );
    } catch (e) {
      // Find first todo step
      try {
        return steps.firstWhere(
          (step) => step.status == StepStatus.todo && step.kind != StepKind.section,
        );
      } catch (e) {
        // Return first non-section step, or first step if all are sections
        return steps.firstWhere(
          (step) => step.kind != StepKind.section,
          orElse: () => steps.first,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return _buildEmptyState(context);
    }

    final currentStep = _getCurrentStep();
    final nonSectionSteps = steps.where((s) => s.kind != StepKind.section).toList();

    return SsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          StepProgressIndicator(steps: steps),
          if (nonSectionSteps.isNotEmpty) ...[
            SizedBox(height: LabSpacing.gapLg()),
            // Divider
            Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
            SizedBox(height: LabSpacing.gapSm()),
          ],
          // Step list
          ...steps.asMap().entries.map((entry) {
            final step = entry.value;
            final isLast = entry.key == steps.length - 1;
            final isCurrent = step.id == currentStep?.id;

            return Column(
              children: [
                StepListItem(
                  step: step,
                  isCurrent: isCurrent,
                  onTap: onStepTap != null
                      ? () => onStepTap!(step)
                      : null,
                ),
                if (!isLast && step.kind != StepKind.section) ...[
                  Divider(
                    height: 1,
                    indent: LabSpacing.gapLg() + 24 + LabSpacing.gapMd(),
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return SsCard(
      child: Padding(
        padding: EdgeInsets.all(LabSpacing.gapXxl()),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checklist_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              SizedBox(height: LabSpacing.gapLg()),
              Text(
                'No steps',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: LabSpacing.gapSm()),
              Text(
                'This run doesn\'t have any steps yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
