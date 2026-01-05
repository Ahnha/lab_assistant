import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings_model.dart';

/// Controller for managing application settings.
/// Loads and saves settings to SharedPreferences.
class AppSettingsController extends ChangeNotifier {
  static const String _themeKeyPref = 'app_theme_key';
  static const String _labModeKeyPref = 'lab_mode_enabled';
  static const String _autoReturnKeyPref = 'auto_return_enabled';

  AppSettingsModel _settings = const AppSettingsModel();
  bool _isLoading = true;

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  /// Text scale factor (computed from settings)
  double get textScale => _settings.textScale;

  /// Spacing scale factor (computed from settings)
  double get spacingScale => _settings.spacingScale;

  /// Load settings from SharedPreferences
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final themeKey = prefs.getString(_themeKeyPref) ?? 'studioAir';
      final labMode = prefs.getBool(_labModeKeyPref) ?? false;
      final autoReturn = prefs.getBool(_autoReturnKeyPref) ?? true;

      _settings = AppSettingsModel(
        themeKey: themeKey,
        labMode: labMode,
        autoReturnToSteps: autoReturn,
      );
    } catch (e) {
      // Use defaults on error
      _settings = const AppSettingsModel();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update theme key
  Future<void> setThemeKey(String themeKey) async {
    _settings = _settings.copyWith(themeKey: themeKey);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKeyPref, themeKey);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Update lab mode
  Future<void> setLabMode(bool enabled) async {
    _settings = _settings.copyWith(labMode: enabled);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_labModeKeyPref, enabled);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Update auto-return setting
  Future<void> setAutoReturnToSteps(bool enabled) async {
    _settings = _settings.copyWith(autoReturnToSteps: enabled);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoReturnKeyPref, enabled);
    } catch (e) {
      // Ignore save errors
    }
  }
}
