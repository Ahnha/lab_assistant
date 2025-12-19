import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _labModeKey = 'lab_mode_enabled';

  /// Get whether Lab Mode is enabled
  static Future<bool> isLabModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_labModeKey) ?? false;
  }

  /// Set Lab Mode enabled state
  static Future<void> setLabModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_labModeKey, enabled);
  }
}
