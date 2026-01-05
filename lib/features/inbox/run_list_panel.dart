import 'package:flutter/material.dart';
import '../../domain/lab_run.dart';
import '../../ui/spacing.dart';
import '../../ui/widgets/ss_card.dart';
import '../../widgets/recipe_badge.dart';
import '../../utils/date_formatter.dart';

/// Panel widget for displaying the list of runs (left sidebar in desktop layout).
class RunListPanel extends StatelessWidget {
  final List<LabRun> runs;
  final LabRun? selectedRun;
  final ValueChanged<LabRun> onRunSelected;
  final ValueChanged<LabRun> onRunDeleted;
  final Future<bool?> Function(BuildContext, LabRun) onDeleteConfirmation;
  final double? spacingScale;
  final bool isLoading;

  const RunListPanel({
    super.key,
    required this.runs,
    this.selectedRun,
    required this.onRunSelected,
    required this.onRunDeleted,
    required this.onDeleteConfirmation,
    this.spacingScale,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scale = spacingScale ?? 1.0;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (runs.isEmpty) {
      return const SizedBox.shrink(); // Empty state handled by parent
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(LabSpacing.gapLg(scale)),
        itemCount: runs.length,
        itemBuilder: (context, index) {
          return _buildRunTile(context, runs[index], scale);
        },
      ),
    );
  }

  Widget _buildRunTile(BuildContext context, LabRun run, double scale) {
    final theme = Theme.of(context);
    final isSelected = selectedRun?.id == run.id;

    return Dismissible(
      key: Key(run.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(context, scale),
      confirmDismiss: (direction) async {
        return await onDeleteConfirmation(context, run);
      },
      onDismissed: (direction) {
        onRunDeleted(run);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: LabSpacing.gapMd(scale)),
        child: SsCard(
          spacingScale: scale,
          backgroundColor: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          child: InkWell(
            onTap: () => onRunSelected(run),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: LabSpacing.tileInsets(scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          run.recipe.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                      ),
                      RecipeBadge(kind: run.recipe.kind),
                    ],
                  ),
                  SizedBox(height: LabSpacing.gapSm(scale)),
                  Text(
                    DateFormatter.formatDateTime(run.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: LabSpacing.gapSm(scale)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${run.completedSteps}/${run.totalSteps}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context, double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: LabSpacing.gapMd(scale)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: LabSpacing.gapXl(scale)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 28,
          ),
          SizedBox(width: LabSpacing.gapSm(scale)),
          Text(
            'Delete',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
