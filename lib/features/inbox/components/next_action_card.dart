import 'package:flutter/material.dart';
import '../../../domain/lab_run.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_kind.dart';
import '../../../domain/step_status.dart';
import '../../../ui/spacing.dart';
import '../../../ui/widgets/ss_card.dart';
import '../../../app/widgets/primary_button.dart';

/// Card that shows the next incomplete step and provides a CTA to continue.
class NextActionCard extends StatelessWidget {
  final LabRun run;
  final VoidCallback? onContinue;
  final double? spacingScale;

  const NextActionCard({
    super.key,
    required this.run,
    this.onContinue,
    this.spacingScale,
  });

  ProcedureStep? _getNextIncompleteStep() {
    for (final step in run.steps) {
      if (step.kind != StepKind.section &&
          step.status != StepStatus.done &&
          step.status != StepStatus.skipped) {
        return step;
      }
    }
    return null;
  }

  int _getStepNumber(ProcedureStep step) {
    int number = 1;
    for (final s in run.steps) {
      if (s.id == step.id) break;
      if (s.kind != StepKind.section) number++;
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;
    final nextStep = _getNextIncompleteStep();

    // Don't show if all steps are complete
    if (nextStep == null) {
      return const SizedBox.shrink();
    }

    final stepNumber = _getStepNumber(nextStep);

    return Padding(
      padding: EdgeInsets.all(LabSpacing.gapLg(scale)),
      child: SsCard(
        spacingScale: scale,
        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: LabSpacing.gapSm(scale)),
                Text(
                  'Next action',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: LabSpacing.gapMd(scale)),
            Text(
              nextStep.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (nextStep.description != null) ...[
              SizedBox(height: LabSpacing.gapXs(scale)),
              Text(
                nextStep.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: LabSpacing.gapSm(scale)),
            Text(
              'Step $stepNumber: ${nextStep.title}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: LabSpacing.gapLg(scale)),
            PrimaryButton(
              label: 'Continue',
              onPressed: onContinue,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
