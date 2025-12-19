import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/recipe_template.dart';

class RecipeTemplateStore {
  static const String _storageKey = 'recipe_templates_v1';

  Future<List<RecipeTemplate>> loadAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => RecipeTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTemplate(RecipeTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final allTemplates = await loadAllTemplates();
    final index = allTemplates.indexWhere((t) => t.id == template.id);
    final updatedTemplate = template.copyWith();
    if (index >= 0) {
      allTemplates[index] = updatedTemplate;
    } else {
      allTemplates.add(updatedTemplate);
    }
    final jsonString = jsonEncode(allTemplates.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> deleteTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final allTemplates = await loadAllTemplates();
    allTemplates.removeWhere((t) => t.id == id);
    final jsonString = jsonEncode(allTemplates.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<RecipeTemplate?> getTemplateById(String id) async {
    final allTemplates = await loadAllTemplates();
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ensures a template exists, creating it if it doesn't.
  /// Returns true if template was created, false if it already existed.
  Future<bool> ensureTemplateExists(RecipeTemplate template) async {
    final existing = await getTemplateById(template.id);
    if (existing != null) {
      return false;
    }
    await saveTemplate(template);
    return true;
  }
}
