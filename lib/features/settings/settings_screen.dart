import 'package:flutter/material.dart';
import '../../data/lab_run_repository.dart';
import '../../app/app_settings_controller.dart';
import '../../app/ui_tokens.dart';
import '../../app/log.dart';
import 'components/settings_section.dart';
import 'components/settings_toggle_row.dart';
import 'components/import_run_card.dart';
import 'appearance_page.dart';
import '../import/import_run_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettingsController settingsController;

  const SettingsScreen({super.key, required this.settingsController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appVersion = '0.1.0';
  final TextEditingController _jsonController = TextEditingController();
  final LabRunRepository _repository = LabRunRepository();
  List<String> _errorMessages = [];

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _importRun() async {
    setState(() {
      _errorMessages = [];
    });

    final jsonText = _jsonController.text.trim();
    if (jsonText.isEmpty) {
      setState(() {
        _errorMessages = ['Please provide JSON data'];
      });
      return;
    }

    final result = ImportRunService.importRunFromJson(jsonText);
    if (!result.success) {
      setState(() {
        _errorMessages = result.errors;
      });
      return;
    }

    try {
      Log.d('SettingsScreen', 'Import started');
      await _repository.save(result.run!);
      Log.d('SettingsScreen', 'Import success: ${result.run!.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Run imported successfully')),
        );
        _jsonController.clear();
        setState(() {
          _errorMessages = [];
        });
      }
    } catch (e) {
      Log.d('SettingsScreen', 'Import failure: $e');
      setState(() {
        _errorMessages = ['Failed to save run: ${e.toString()}'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UITokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Version Section
            SettingsSection(
              title: 'App Version',
              child: Text(
                _appVersion,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: UITokens.spacingXXL),

            // Appearance Section
            SettingsSection(
              title: 'Appearance',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(
                      _getThemeDisplayName(
                        widget.settingsController.settings.themeKey,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppearancePage(
                            settingsController: widget.settingsController,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SettingsToggleRow(
                    label: 'Lab Mode',
                    description:
                        'Improve readability with larger text and increased padding',
                    value: widget.settingsController.settings.labMode,
                    onChanged: (value) {
                      widget.settingsController.setLabMode(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: UITokens.spacingXXL),

            // Behavior Section
            SettingsSection(
              title: 'Behavior',
              child: SettingsToggleRow(
                label: 'Auto-return to Steps when section complete',
                description:
                    'Automatically navigate back to Steps tab when an ingredient section is completed',
                value: widget.settingsController.settings.autoReturnToSteps,
                onChanged: (value) {
                  widget.settingsController.setAutoReturnToSteps(value);
                },
              ),
            ),
            const SizedBox(height: UITokens.spacingXXL),

            // Import / Export Section
            SettingsSection(
              title: 'Import / Export',
              description: 'Paste JSON exported from this app to recreate a run.',
              child: ImportRunCard(
                controller: _jsonController,
                onImport: _importRun,
                errorMessages: _errorMessages.isNotEmpty ? _errorMessages : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(String themeKey) {
    switch (themeKey) {
      case 'studioAir':
        return 'Studio Air';
      case 'studioNight':
        return 'Studio Night';
      case 'studioFocus':
        return 'Studio Focus';
      case 'studioAirLuxe':
        return 'Studio Air Luxe';
      case 'powder':
        return 'Powder';
      default:
        return themeKey;
    }
  }
}
