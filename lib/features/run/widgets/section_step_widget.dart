import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../app/widgets/app_card.dart';

/// Widget for displaying section/heading steps.
/// These steps are non-interactive and serve as visual separators.
class SectionStepWidget extends StatelessWidget {
  final ProcedureStep step;

  const SectionStepWidget({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (step.description != null && step.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              step.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
