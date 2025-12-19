import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../data/lab_run_repository.dart';
import '../../domain/lab_run.dart';
import '../../utils/date_formatter.dart';
import '../../app/log.dart';
import '../../app/ui_tokens.dart';
import 'run_detail_screen.dart';
import '../../widgets/recipe_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('History'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _runs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No archived runs',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRuns,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _runs.length,
                itemBuilder: (context, index) {
                  return _buildRunTile(_runs[index]);
                },
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
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created: ${DateFormatter.formatDateTime(run.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (run.finishedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Finished: ${DateFormatter.formatDateTime(run.finishedAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${run.completedSteps}/${run.totalSteps}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'export') {
                    await _exportRun(run);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, size: 20),
                        SizedBox(width: UITokens.spacingS),
                        Text('Export JSON'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 28,
          ),
          const SizedBox(width: 8),
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
