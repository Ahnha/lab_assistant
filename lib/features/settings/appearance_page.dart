import 'package:flutter/material.dart';
import 'package:skin_studio_design_tokens/design_tokens.dart';
import '../../app/app_settings_controller.dart';
import '../../ui/layout.dart';
import '../../ui/spacing.dart';
import '../../ui/widgets/ss_card.dart';

/// Available theme keys
const List<String> _themeKeys = [
  'studioAir',
  'studioNight',
  'studioFocus',
  'studioAirLuxe',
  'powder',
];

/// Theme display names
const Map<String, String> _themeNames = {
  'studioAir': 'Studio Air',
  'studioNight': 'Studio Night',
  'studioFocus': 'Studio Focus',
  'studioAirLuxe': 'Studio Air Luxe',
  'powder': 'Powder',
};

class AppearancePage extends StatelessWidget {
  final AppSettingsController settingsController;

  const AppearancePage({
    super.key,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    final spacingScale = settingsController.spacingScale;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
      ),
      body: ConstrainedPage(
        spacingScale: spacingScale,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: LabSpacing.gapLg(spacingScale)),
              if (isWide)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: LabSpacing.gapLg(spacingScale),
                    mainAxisSpacing: LabSpacing.gapLg(spacingScale),
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _themeKeys.length,
                  itemBuilder: (context, index) {
                    final themeKey = _themeKeys[index];
                    return _ThemeCard(
                      themeKey: themeKey,
                      isSelected: settingsController.settings.themeKey == themeKey,
                      onTap: () {
                        settingsController.setThemeKey(themeKey);
                      },
                      spacingScale: spacingScale,
                    );
                  },
                )
              else
                ..._themeKeys.map((themeKey) => _ThemeCard(
                      themeKey: themeKey,
                      isSelected: settingsController.settings.themeKey == themeKey,
                      onTap: () {
                        settingsController.setThemeKey(themeKey);
                      },
                      spacingScale: spacingScale,
                    )),
              SizedBox(height: LabSpacing.gapXxl(spacingScale)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String themeKey;
  final bool isSelected;
  final VoidCallback onTap;
  final double? spacingScale;

  const _ThemeCard({
    required this.themeKey,
    required this.isSelected,
    required this.onTap,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final scale = spacingScale ?? 1.0;
    final theme = Theme.of(context);
    // Build a preview theme to show colors
    final previewTheme = buildSkinStudioTheme(themeKey: themeKey);

    return SsCard(
      spacingScale: scale,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: LabSpacing.cardInsets(scale),
            child: Row(
              children: [
                // Preview tile
                Container(
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    color: previewTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: previewTheme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20 * scale,
                        height: 6 * scale,
                        decoration: BoxDecoration(
                          color: previewTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 9 * scale,
                          color: previewTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5 * scale,
                          vertical: 2 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: previewTheme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Tag',
                          style: TextStyle(
                            fontSize: 7 * scale,
                            color: previewTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: LabSpacing.gapLg(scale)),
                // Theme name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _themeNames[themeKey] ?? themeKey,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: LabSpacing.gapXs(scale)),
                      Text(
                        _getThemeDescription(themeKey),
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: LabSpacing.gapLg(scale)),
                // Selected indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeDescription(String themeKey) {
    switch (themeKey) {
      case 'studioAir':
        return 'Light, airy, minimalist';
      case 'studioNight':
        return 'Dark mode for low light';
      case 'studioFocus':
        return 'High contrast for clarity';
      case 'studioAirLuxe':
        return 'Refined, elegant light theme';
      case 'powder':
        return 'Soft, muted pastels';
      default:
        return '';
    }
  }
}
