import 'package:flutter/material.dart';
import '../../ui/spacing.dart';
import '../../app/widgets/secondary_button.dart';
import '../../app/widgets/primary_button.dart';

/// Empty state widget for when no run is selected (desktop right pane).
class RunEmptyState extends StatelessWidget {
  final VoidCallback? onOpenLatest;
  final VoidCallback? onImportRun;
  final double? spacingScale;

  const RunEmptyState({
    super.key,
    this.onOpenLatest,
    this.onImportRun,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(LabSpacing.gapXxl(scale)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            SizedBox(height: LabSpacing.gapXxl(scale)),
            Text(
              'Select a run',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: LabSpacing.gapSm(scale)),
            Text(
              'Choose a run from the list to view details and continue your work',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onOpenLatest != null || onImportRun != null) ...[
              SizedBox(height: LabSpacing.gapXxl(scale)),
              if (onOpenLatest != null)
                SecondaryButton(
                  label: 'Open latest run',
                  onPressed: onOpenLatest,
                  isFullWidth: false,
                ),
              if (onImportRun != null) ...[
                SizedBox(height: LabSpacing.gapMd(scale)),
                PrimaryButton(
                  label: 'Import run',
                  onPressed: onImportRun,
                  isFullWidth: false,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
