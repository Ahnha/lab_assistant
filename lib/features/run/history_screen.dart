import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../data/lab_run_repository.dart';
import '../../domain/lab_run.dart';
import '../../utils/date_formatter.dart';
import '../../app/log.dart';
import '../../app/app_settings_controller.dart';
import '../../ui/layout.dart';
import '../../ui/spacing.dart';
import '../../ui/components/ss_page_header.dart';
import '../../ui/widgets/ss_card.dart';
import 'run_detail_screen.dart';
import '../../widgets/recipe_badge.dart';

class HistoryScreen extends StatefulWidget {
  final AppSettingsController settingsController;
  final void Function(int index)? onNavigateToTab;

  const HistoryScreen({
    super.key,
    required this.settingsController,
    this.onNavigateToTab,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LabRunRepository _repository = LabRunRepository();
  List<LabRun> _runs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() {
      _isLoading = true;
    });
    final archivedRuns = await _repository.loadArchivedRuns();
    setState(() {
      _runs = archivedRuns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacingScale = widget.settingsController.spacingScale;

    return Scaffold(
      body: Column(
        children: [
          SsPageHeader(
            title: 'History',
            spacingScale: spacingScale,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _runs.isEmpty
                    ? _buildEmptyState(spacingScale)
                    : ConstrainedPage(
                        spacingScale: spacingScale,
                        child: RefreshIndicator(
                          onRefresh: _loadRuns,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              vertical: LabSpacing.gapLg(spacingScale),
                            ),
                            itemCount: _runs.length,
                            itemBuilder: (context, index) {
                              return _buildRunTile(_runs[index], spacingScale);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double spacingScale) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: LabSpacing.pageInsets(spacingScale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 64 * spacingScale,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.6),
              ),
              SizedBox(height: LabSpacing.gapXxl(spacingScale)),
              Text(
                'No archived runs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: LabSpacing.gapSm(spacingScale)),
              Text(
                'Completed runs will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: LabSpacing.gapXxl(spacingScale)),
              FilledButton.icon(
                onPressed: () => widget.onNavigateToTab?.call(0),
                icon: const Icon(Icons.inbox, size: 20),
                label: const Text('Go to Inbox'),
              ),
              SizedBox(height: LabSpacing.gapSm(spacingScale)),
              Text(
                'Finish a run to archive it.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunTile(LabRun run, double spacingScale) {
    return Dismissible(
      key: Key(run.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(context, spacingScale),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context, run);
      },
      onDismissed: (direction) {
        _deleteRun(run);
      },
      child: SsCard(
        spacingScale: spacingScale,
        child: InkWell(
          onTap: () async {
            final updatedRun = await Navigator.push<LabRun>(
              context,
              MaterialPageRoute(
                builder: (context) => RunDetailScreen(run: run),
              ),
            );
            if (updatedRun != null) {
              await _repository.save(updatedRun);
              _loadRuns();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: LabSpacing.tileInsets(spacingScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        run.recipe.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    RecipeBadge(kind: run.recipe.kind),
                  ],
                ),
                SizedBox(height: LabSpacing.gapSm(spacingScale)),
                Text(
                  'Created: ${DateFormatter.formatDateTime(run.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (run.finishedAt != null) ...[
                  SizedBox(height: LabSpacing.gapXs(spacingScale)),
                  Text(
                    'Finished: ${DateFormatter.formatDateTime(run.finishedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
                SizedBox(height: LabSpacing.gapSm(spacingScale)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${run.completedSteps}/${run.totalSteps}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) async {
                        if (value == 'export') {
                          await _exportRun(run);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(
                                Icons.file_download,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              SizedBox(width: LabSpacing.gapSm(spacingScale)),
                              Text('Export JSON'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context, double spacingScale) {
    return Container(
      margin: EdgeInsets.only(bottom: LabSpacing.gapMd(spacingScale)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: LabSpacing.gapXl(spacingScale)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 28,
          ),
          SizedBox(width: LabSpacing.gapSm(spacingScale)),
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

  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    LabRun run,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete run?'),
        content: const Text('This will remove the run from this phone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteRun(LabRun run) async {
    final deletedRun = run;
    Log.d('HistoryScreen', 'Deleting run: ${run.id}');
    await _repository.delete(run.id);
    setState(() {
      _runs.removeWhere((r) => r.id == run.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Run deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _repository.save(deletedRun);
              _loadRuns();
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _exportRun(LabRun run) async {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(run.toJson());

      await Clipboard.setData(ClipboardData(text: formattedJson));
      Log.d('HistoryScreen', 'Exported run to clipboard: ${run.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Log.d('HistoryScreen', 'Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
