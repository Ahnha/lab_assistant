import '../domain/lab_run.dart';
import 'lab_run_store.dart';
import '../app/log.dart';

/// Repository layer wrapping LabRunStore.
///
/// Provides a clean interface for widgets to interact with lab run data
/// without directly accessing SharedPreferences. This abstraction makes it
/// easier to swap storage implementations in the future.
class LabRunRepository {
  final LabRunStore _store = LabRunStore();

  /// Load all active (non-archived) runs.
  Future<List<LabRun>> loadActiveRuns() async {
    final allRuns = await _store.loadAllRuns();
    return allRuns.where((r) => !r.archived).toList();
  }

  /// Load all archived runs.
  Future<List<LabRun>> loadArchivedRuns() async {
    final allRuns = await _store.loadAllRuns();
    return allRuns.where((r) => r.archived).toList();
  }

  /// Save a run. Creates new or updates existing.
  Future<void> save(LabRun run) async {
    Log.d('Repository', 'Saving run: ${run.id}');
    await _store.saveRun(run);
    Log.d('Repository', 'Run saved: ${run.id}');
  }

  /// Delete a run permanently.
  Future<void> delete(String id) async {
    Log.d('Repository', 'Deleting run: $id');
    await _store.deleteRun(id);
  }

  /// Archive a run (marks as archived without deleting).
  Future<void> archive(String id) async {
    await _store.archiveRun(id);
  }
}
