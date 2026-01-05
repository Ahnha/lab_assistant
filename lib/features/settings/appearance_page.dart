import 'package:flutter/material.dart';
import 'package:skin_studio_design_tokens/design_tokens.dart';
import '../../app/app_settings_controller.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ..._themeKeys.map((themeKey) => _ThemeCard(
                themeKey: themeKey,
                isSelected: settingsController.settings.themeKey == themeKey,
                onTap: () {
                  settingsController.setThemeKey(themeKey);
                },
              )),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String themeKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.themeKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build a preview theme to show colors
    final previewTheme = buildSkinStudioTheme(themeKey: themeKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Preview tile
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: previewTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: previewTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: previewTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 10,
                        color: previewTheme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: previewTheme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tag',
                        style: TextStyle(
                          fontSize: 8,
                          color: previewTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Theme name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _themeNames[themeKey] ?? themeKey,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getThemeDescription(themeKey),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // Selected indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
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
