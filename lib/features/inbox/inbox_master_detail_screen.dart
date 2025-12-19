import 'package:flutter/material.dart';
import '../../data/lab_run_repository.dart';
import '../../data/app_settings.dart';
import '../../domain/lab_run.dart';
import '../../utils/date_formatter.dart';
import '../../app/log.dart';
import '../run/run_detail_screen.dart';
import '../../widgets/recipe_badge.dart';
import 'dart:math' as math;

class InboxMasterDetailScreen extends StatefulWidget {
  const InboxMasterDetailScreen({super.key});

  @override
  State<InboxMasterDetailScreen> createState() =>
      _InboxMasterDetailScreenState();
}

class _InboxMasterDetailScreenState extends State<InboxMasterDetailScreen> {
  final LabRunRepository _repository = LabRunRepository();
  List<LabRun> _runs = [];
  bool _isLoading = true;
  LabRun? _selectedRun;
  String? _selectedRunId;
  bool _labModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadRuns();
    _loadLabModeSetting();
  }

  Future<void> _loadLabModeSetting() async {
    final enabled = await AppSettings.isLabModeEnabled();
    if (mounted) {
      setState(() {
        _labModeEnabled = enabled;
      });
    }
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
    // Auto-select first run if available and none selected
    if (activeRuns.isNotEmpty && _selectedRun == null) {
      _selectedRun = activeRuns.firstWhere(
        (r) => r.id == _selectedRunId,
        orElse: () => activeRuns.first,
      );
      _selectedRunId = _selectedRun!.id;
    }
  }

  void _selectRun(LabRun run) {
    setState(() {
      _selectedRun = run;
      _selectedRunId = run.id;
    });
  }

  Future<void> _onRunUpdated(LabRun updatedRun) async {
    // Update the run in our list (controller already saved to repository)
    setState(() {
      final index = _runs.indexWhere((r) => r.id == updatedRun.id);
      if (index != -1) {
        _runs[index] = updatedRun;
        // Update selected run if it's the one that was updated
        if (_selectedRun?.id == updatedRun.id) {
          _selectedRun = updatedRun;
        }
      }
    });
  }

  Future<void> _onRunDeleted(String runId) async {
    await _repository.delete(runId);
    setState(() {
      _runs.removeWhere((r) => r.id == runId);
      if (_selectedRun?.id == runId) {
        _selectedRun = _runs.isNotEmpty ? _runs.first : null;
        _selectedRunId = _selectedRun?.id;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Run deleted')));
    }
  }

  void _deleteRun(LabRun run) async {
    final deletedRun = run;
    Log.d('InboxMasterDetailScreen', 'Deleting run: ${run.id}');
    await _repository.delete(run.id);
    setState(() {
      _runs.removeWhere((r) => r.id == run.id);
      if (_selectedRun?.id == run.id) {
        _selectedRun = _runs.isNotEmpty ? _runs.first : null;
        _selectedRunId = _selectedRun?.id;
      }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final masterWidth = math.min(420.0, math.max(360.0, screenWidth * 0.4));

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), centerTitle: true),
      body: Row(
        children: [
          // Master: Inbox list
          Container(
            width: masterWidth,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildMasterPane(),
          ),
          // Detail: Run detail screen
          Expanded(
            child: _selectedRun != null
                ? _RunDetailWrapper(
                    key: ValueKey(_selectedRun!.id),
                    run: _selectedRun!,
                    onRunUpdated: _onRunUpdated,
                    onRunDeleted: _onRunDeleted,
                  )
                : _buildEmptyDetailState(),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterPane() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_runs.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadRuns,
      child: ListView.builder(
        padding: EdgeInsets.all(_labModeEnabled ? 20 : 16),
        itemCount: _runs.length,
        itemBuilder: (context, index) {
          return _buildRunTile(_runs[index]);
        },
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

  Widget _buildEmptyDetailState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a run to view details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunTile(LabRun run) {
    final isSelected = _selectedRunId == run.id;
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
        margin: EdgeInsets.only(bottom: _labModeEnabled ? 16 : 12),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: ListTile(
          contentPadding: EdgeInsets.all(_labModeEnabled ? 20 : 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  run.recipe.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
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
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          trailing: Text(
            '${run.completedSteps}/${run.totalSteps}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
            ),
          ),
          onTap: () {
            _selectRun(run);
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
}

/// Wrapper for RunDetailScreen that works in the master/detail layout
class _RunDetailWrapper extends StatefulWidget {
  final LabRun run;
  final ValueChanged<LabRun> onRunUpdated;
  final ValueChanged<String> onRunDeleted;

  const _RunDetailWrapper({
    required Key key,
    required this.run,
    required this.onRunUpdated,
    required this.onRunDeleted,
  }) : super(key: key);

  @override
  State<_RunDetailWrapper> createState() => _RunDetailWrapperState();
}

class _RunDetailWrapperState extends State<_RunDetailWrapper> {
  void _handleRunUpdate(LabRun updatedRun) {
    widget.onRunUpdated(updatedRun);
  }

  void _handleRunDeleted() {
    widget.onRunDeleted(widget.run.id);
  }

  @override
  Widget build(BuildContext context) {
    // Use the run directly - the key ensures widget recreation when run ID changes
    return RunDetailScreen(
      key: ValueKey(widget.run.id),
      run: widget.run,
      onRunUpdated: _handleRunUpdate,
      onRunDeleted: _handleRunDeleted,
      isEmbedded: true,
    );
  }
}
