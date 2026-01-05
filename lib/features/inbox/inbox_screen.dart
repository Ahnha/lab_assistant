import 'package:flutter/material.dart';
import '../../data/lab_run_repository.dart';
import '../../domain/lab_run.dart';
import '../../domain/recipe_kind.dart';
import '../../app/app_settings_controller.dart';
import '../../ui/spacing.dart';
import '../../ui/components/ss_page_header.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/secondary_button.dart';
import '../../utils/date_formatter.dart';
import 'run_workspace.dart';
import 'run_list_panel.dart';
import 'run_empty_state.dart';
import '../run/run_detail_screen.dart';

/// Responsive Inbox screen with 2-pane layout for desktop and single column for mobile.
class InboxScreen extends StatefulWidget {
  final AppSettingsController settingsController;
  final void Function(int index)? onNavigateToTab;

  const InboxScreen({
    super.key,
    required this.settingsController,
    this.onNavigateToTab,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final LabRunRepository _repository = LabRunRepository();
  List<LabRun> _runs = [];
  bool _isLoading = true;
  LabRun? _selectedRun;

  // Breakpoint for responsive layout
  static const double _breakpoint = 840.0;

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
      // Auto-select first run on desktop if none selected
      if (activeRuns.isNotEmpty && _selectedRun == null) {
        _selectedRun = activeRuns.first;
      }
    });
  }

  void _selectRun(LabRun run) {
    setState(() {
      _selectedRun = run;
    });
  }

  Future<void> _navigateToRunDetails(LabRun run) async {
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
    await _repository.delete(run.id);
    setState(() {
      _runs.removeWhere((r) => r.id == run.id);
      if (_selectedRun?.id == run.id) {
        _selectedRun = _runs.isNotEmpty ? _runs.first : null;
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

  void _handleRunUpdated(LabRun updatedRun) {
    setState(() {
      final index = _runs.indexWhere((r) => r.id == updatedRun.id);
      if (index != -1) {
        _runs[index] = updatedRun;
        if (_selectedRun?.id == updatedRun.id) {
          _selectedRun = updatedRun;
        }
      }
    });
  }

  void _handleRunDeleted() {
    if (_selectedRun != null) {
      _deleteRun(_selectedRun!);
    }
  }

  void _openLatestRun() {
    if (_runs.isNotEmpty) {
      _selectRun(_runs.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacingScale = widget.settingsController.spacingScale;
    final isDesktop = screenWidth >= _breakpoint;

    return Scaffold(
      body: Column(
        children: [
          SsPageHeader(
            title: 'Inbox',
            spacingScale: spacingScale,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _runs.isEmpty
                    ? _buildEmptyState(spacingScale)
                    : isDesktop
                        ? _buildDesktopLayout(spacingScale)
                        : _buildMobileLayout(spacingScale),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double spacingScale) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: LabSpacing.pageInsets(spacingScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 80 * spacingScale,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            SizedBox(height: LabSpacing.gapXxl(spacingScale)),
            Text(
              'No active runs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: LabSpacing.gapSm(spacingScale)),
            Text(
              'Import a run to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: LabSpacing.gapXxl(spacingScale)),
            FilledButton.icon(
              onPressed: () => widget.onNavigateToTab?.call(2),
              icon: const Icon(Icons.settings, size: 20),
              label: const Text('Go to Settings'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: LabSpacing.gapXl(spacingScale),
                  vertical: LabSpacing.gapLg(spacingScale),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double spacingScale) {
    return Row(
      children: [
        // Left panel: Run list
        Container(
          width: 400,
          child: RunListPanel(
            runs: _runs,
            selectedRun: _selectedRun,
            onRunSelected: _selectRun,
            onRunDeleted: _deleteRun,
            onDeleteConfirmation: _showDeleteConfirmationDialog,
            spacingScale: spacingScale,
            isLoading: false,
          ),
        ),
        // Right panel: Run workspace or empty state
        Expanded(
          child: _selectedRun != null
              ? RunWorkspace(
                  run: _selectedRun!,
                  onRunUpdated: _handleRunUpdated,
                  onRunDeleted: _handleRunDeleted,
                  spacingScale: spacingScale,
                )
              : RunEmptyState(
                  onOpenLatest: _openLatestRun,
                  onImportRun: () {
                    widget.onNavigateToTab?.call(2);
                  },
                  spacingScale: spacingScale,
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double spacingScale) {
    return RefreshIndicator(
      onRefresh: _loadRuns,
      child: ListView.builder(
        padding: EdgeInsets.all(LabSpacing.gapLg(spacingScale)),
        itemCount: _runs.length,
        itemBuilder: (context, index) {
          return _buildRunTile(_runs[index], spacingScale);
        },
      ),
    );
  }

  Widget _buildRunTile(LabRun run, double spacingScale) {
    return Padding(
      padding: EdgeInsets.only(bottom: LabSpacing.gapMd(spacingScale)),
      child: Card(
        child: ListTile(
          contentPadding: EdgeInsets.all(LabSpacing.gapLg(spacingScale)),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  run.recipe.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: run.recipe.kind == RecipeKind.soap
                      ? Colors.orange.shade100
                      : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  run.recipe.kind.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: run.recipe.kind == RecipeKind.soap
                        ? Colors.orange.shade900
                        : Colors.purple.shade900,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: LabSpacing.gapSm(spacingScale)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.formatDateTime(run.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: LabSpacing.gapXs(spacingScale)),
                Text(
                  '${run.completedSteps}/${run.totalSteps}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: () => _navigateToRunDetails(run),
        ),
      ),
    );
  }
}
