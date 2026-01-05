import 'package:flutter/material.dart';
import '../../../domain/lab_run.dart';
import '../../../ui/spacing.dart';
import '../../../widgets/recipe_badge.dart';
import '../../../utils/date_formatter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../app/log.dart';
import '../../../data/lab_run_repository.dart';
import '../../../app/widgets/primary_button.dart';
import '../../../app/widgets/secondary_button.dart';

/// Premium workspace header for run details.
/// Shows title, type chip, progress, and overflow menu.
class WorkspaceHeader extends StatelessWidget {
  final LabRun run;
  final ValueChanged<LabRun>? onRunUpdated;
  final VoidCallback? onRunDeleted;
  final double? spacingScale;

  const WorkspaceHeader({
    super.key,
    required this.run,
    this.onRunUpdated,
    this.onRunDeleted,
    this.spacingScale,
  });

  Future<void> _exportRun(BuildContext context) async {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(run.toJson());
      await Clipboard.setData(ClipboardData(text: formattedJson));
      Log.d('WorkspaceHeader', 'Exported run to clipboard: ${run.id}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Run JSON copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Log.d('WorkspaceHeader', 'Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteRunDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Run'),
        content: const Text(
          'Are you sure you want to delete this run? This action cannot be undone.',
        ),
        actions: [
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PrimaryButton(
            label: 'Delete',
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              Log.d('WorkspaceHeader', 'Deleting run: ${run.id}');
              if (onRunDeleted != null) {
                onRunDeleted!();
              } else {
                final repository = LabRunRepository();
                await repository.delete(run.id);
                if (context.mounted) {
                  navigator.pop();
                }
              }
            },
            backgroundColor: Theme.of(context).colorScheme.error,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;

    return Container(
      padding: EdgeInsets.all(LabSpacing.gapXl(scale)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.recipe.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: LabSpacing.gapXs(scale)),
                Text(
                  DateFormatter.formatDateTime(run.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: LabSpacing.gapLg(scale)),
          Row(
            children: [
              RecipeBadge(kind: run.recipe.kind),
              SizedBox(width: LabSpacing.gapMd(scale)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: LabSpacing.gapMd(scale),
                  vertical: LabSpacing.gapSm(scale),
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${run.completedSteps}/${run.totalSteps}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: LabSpacing.gapSm(scale)),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'export') {
                    _exportRun(context);
                  } else if (value == 'delete') {
                    _showDeleteRunDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, size: 20),
                        SizedBox(width: 8),
                        Text('Export JSON'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete run', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
