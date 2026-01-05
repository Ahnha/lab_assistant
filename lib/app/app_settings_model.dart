/// Application settings model.
/// Contains theme and behavior preferences.
class AppSettingsModel {
  final String themeKey;
  final bool labMode;
  final bool autoReturnToSteps;

  const AppSettingsModel({
    this.themeKey = 'studioAir',
    this.labMode = false,
    this.autoReturnToSteps = true,
  });

  AppSettingsModel copyWith({
    String? themeKey,
    bool? labMode,
    bool? autoReturnToSteps,
  }) {
    return AppSettingsModel(
      themeKey: themeKey ?? this.themeKey,
      labMode: labMode ?? this.labMode,
      autoReturnToSteps: autoReturnToSteps ?? this.autoReturnToSteps,
    );
  }

  /// Computed text scale factor for accessibility/lab mode
  double get textScale => labMode ? 1.10 : 1.0;

  /// Computed spacing scale factor for lab mode
  double get spacingScale => labMode ? 1.15 : 1.0;
}
