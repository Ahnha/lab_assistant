import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../data/lab_run_repository.dart';
import '../../domain/lab_run.dart';
import '../../utils/date_formatter.dart';
import '../../app/log.dart';
import '../../app/ui_tokens.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/secondary_button.dart';
import '../run/run_detail_screen.dart';
import '../../widgets/recipe_badge.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final LabRunRepository _repository = LabRunRepository();
  List<LabRun> _runs = [];
  bool _isLoading = true;
  bool _labModeEnabled = false;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _runs.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadRuns,
              child: ListView.builder(
                padding: EdgeInsets.all(
                  _labModeEnabled ? UITokens.spacingXL : UITokens.spacingL,
                ),
                itemCount: _runs.length,
                itemBuilder: (context, index) {
                  return _buildRunTile(_runs[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active runs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Import a run to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunTile(LabRun run) {
    return Dismissible(
      key: Key(run.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(context),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context, run);
      },
      onDismissed: (direction) {
        _deleteRun(run);
      },
      child: Card(
        margin: EdgeInsets.only(
          bottom: _labModeEnabled ? UITokens.spacingL : UITokens.spacingM,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(
            _labModeEnabled ? UITokens.spacingXL : UITokens.spacingL,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  run.recipe.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              RecipeBadge(kind: run.recipe.kind),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              DateFormatter.formatDateTime(run.createdAt),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          trailing: Text(
            '${run.completedSteps}/${run.totalSteps}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
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
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: UITokens.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: UITokens.borderRadiusM,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: UITokens.spacingXL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 28,
          ),
          const SizedBox(width: UITokens.spacingS),
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
