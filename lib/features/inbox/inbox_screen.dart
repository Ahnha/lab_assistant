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
import '../../ui/widgets/ss_empty_state.dart';
import '../../ui/widgets/ss_card.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/secondary_button.dart';
import '../run/run_detail_screen.dart';
import '../../widgets/recipe_badge.dart';

class InboxScreen extends StatefulWidget {
  final AppSettingsController settingsController;

  const InboxScreen({super.key, required this.settingsController});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
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
    final activeRuns = await _repository.loadActiveRuns();
    setState(() {
      _runs = activeRuns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacingScale = widget.settingsController.spacingScale;

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), centerTitle: true),
      body: _isLoading
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
    );
  }

  Widget _buildEmptyState(double spacingScale) {
    return SsEmptyState(
      icon: Icons.inbox_outlined,
      title: 'No active runs',
      subtitle: 'Import a run to get started',
      ctaLabel: 'Go to Settings',
      onCtaPressed: () {
        // Note: In a real implementation, you might want to use a callback
        // or navigator key to switch to the Settings tab
        // For now, this is a placeholder
      },
      spacingScale: spacingScale,
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
            child: Row(
              children: [
                Expanded(
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
                        DateFormatter.formatDateTime(run.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: LabSpacing.gapLg(spacingScale)),
                Text(
                  '${run.completedSteps}/${run.totalSteps}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          PrimaryButton(
            label: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
            backgroundColor: Theme.of(context).colorScheme.error,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  void _deleteRun(LabRun run) async {
    final deletedRun = run;
    Log.d('InboxScreen', 'Deleting run: ${run.id}');
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

  Future<void> _archiveRun(LabRun run) async {
    Log.d('InboxScreen', 'Archiving run: ${run.id}');
    final archivedRun = LabRun(
      id: run.id,
      createdAt: run.createdAt,
      recipe: run.recipe,
      batchCode: run.batchCode,
      steps: run.steps,
      notes: run.notes,
      archived: true,
      finishedAt: run.finishedAt ?? DateTime.now(),
      formula: run.formula,
      templateId: run.templateId,
      ingredientChecks: run.ingredientChecks,
    );
    await _repository.save(archivedRun);
    _loadRuns();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Run archived'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportRun(LabRun run) async {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(run.toJson());

      await Clipboard.setData(ClipboardData(text: formattedJson));
      Log.d('InboxScreen', 'Exported run to clipboard: ${run.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Log.d('InboxScreen', 'Export failed: $e');
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
