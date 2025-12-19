import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/lab_run.dart';

class LabRunStore {
  static const String _storageKey = 'lab_runs_v1';

  Future<List<LabRun>> loadAllRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => LabRun.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRun(LabRun run) async {
    final prefs = await SharedPreferences.getInstance();
    final allRuns = await loadAllRuns();
    final index = allRuns.indexWhere((r) => r.id == run.id);
    if (index >= 0) {
      allRuns[index] = run;
    } else {
      allRuns.add(run);
    }
    final jsonString = jsonEncode(allRuns.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> archiveRun(String id) async {
    final allRuns = await loadAllRuns();
    final run = allRuns.firstWhere((r) => r.id == id);
    final updatedRun = LabRun(
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
    await saveRun(updatedRun);
  }

  Future<void> deleteRun(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final allRuns = await loadAllRuns();
    allRuns.removeWhere((r) => r.id == id);
    final jsonString = jsonEncode(allRuns.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
