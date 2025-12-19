import 'package:flutter/material.dart';
import '../../data/lab_run_repository.dart';
import '../../data/app_settings.dart';
import '../../domain/lab_run_parser.dart';
import '../../domain/lab_run_validator.dart';
import '../../app/log.dart';
import '../../app/ui_tokens.dart';
import '../templates/templates_screen.dart';
import 'components/settings_section.dart';
import 'components/settings_toggle_row.dart';
import 'components/import_run_card.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({super.key, this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appVersion = '0.1.0';
  final TextEditingController _jsonController = TextEditingController();
  final LabRunRepository _repository = LabRunRepository();
  List<String> _errorMessages = [];
  bool _labModeEnabled = false;
  bool _autoReturnEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLabModeSetting();
    _loadAutoReturnSetting();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadLabModeSetting() async {
    final enabled = await AppSettings.isLabModeEnabled();
    if (mounted) {
      setState(() {
        _labModeEnabled = enabled;
      });
    }
  }

  Future<void> _toggleLabMode(bool value) async {
    await AppSettings.setLabModeEnabled(value);
    setState(() {
      _labModeEnabled = value;
    });
    widget.onSettingsChanged?.call();
  }

  Future<void> _loadAutoReturnSetting() async {
    final enabled = await AppSettings.isAutoReturnEnabled();
    if (mounted) {
      setState(() {
        _autoReturnEnabled = enabled;
      });
    }
  }

  Future<void> _toggleAutoReturn(bool value) async {
    await AppSettings.setAutoReturnEnabled(value);
    setState(() {
      _autoReturnEnabled = value;
    });
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

    // Validate JSON structure first
    final structureErrors = LabRunValidator.validateJsonStructure(jsonText);
    if (structureErrors.isNotEmpty) {
      setState(() {
        _errorMessages = structureErrors;
      });
      return;
    }

    try {
      Log.d('SettingsScreen', 'Import started');
      // Import flow: parse -> validate -> save
      // Parser handles tolerant parsing (string numbers, missing fields, etc.)
      final run = LabRunParser.parse(jsonText);

      // Validator returns friendly error messages for UI display
      final validationErrors = LabRunValidator.validate(run);
      if (validationErrors.isNotEmpty) {
        setState(() {
          _errorMessages = validationErrors;
        });
        Log.d(
          'SettingsScreen',
          'Import validation failed: ${validationErrors.join(", ")}',
        );
        return;
      }

      // Save via repository (abstracts away SharedPreferences)
      await _repository.save(run);
      Log.d('SettingsScreen', 'Import success: ${run.id}');

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
        _errorMessages = ['Failed to import: ${e.toString()}'];
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

            // Preferences Section
            SettingsSection(
              title: 'Preferences',
              child: Column(
                children: [
                  SettingsToggleRow(
                    label: 'Lab Mode',
                    description:
                        'Improve readability with larger text and increased padding',
                    value: _labModeEnabled,
                    onChanged: _toggleLabMode,
                  ),
                  const Divider(height: 1),
                  SettingsToggleRow(
                    label: 'Auto-return to Steps when section complete',
                    description:
                        'Automatically navigate back to Steps tab when an ingredient section is completed',
                    value: _autoReturnEnabled,
                    onChanged: _toggleAutoReturn,
                  ),
                ],
              ),
            ),
            const SizedBox(height: UITokens.spacingXXL),

            // Templates Section
            SettingsSection(
              title: 'Templates',
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Recipe Templates'),
                subtitle: const Text('View and manage recipe templates'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TemplatesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: UITokens.spacingXXL),

            // Import / Export Section
            SettingsSection(
              title: 'Import / Export',
              description:
                  'Paste JSON exported from this app to recreate a run.',
              child: ImportRunCard(
                controller: _jsonController,
                onImport: _importRun,
                errorMessages: _errorMessages.isNotEmpty
                    ? _errorMessages
                    : null,
                rightHeaderActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _jsonController.text = _getSampleSoapJson();
                      },
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: const Text('Sample: Soap'),
                    ),
                    const SizedBox(width: UITokens.spacingXS),
                    TextButton.icon(
                      onPressed: () {
                        _jsonController.text = _getSampleCreamJson();
                      },
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: const Text('Sample: Cream'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSampleSoapJson() {
    final now = DateTime.now();
    return '''{
  "id": "sample-soap-${now.microsecondsSinceEpoch}",
  "createdAt": "${now.toIso8601String()}",
  "recipe": {
    "id": "recipe-soap-sample",
    "kind": "soap",
    "name": "Basic Cold Process Soap",
    "defaultBatchSizeGrams": 1000
  },
  "batchCode": "SOAP-SAMPLE",
  "formula": {
    "batchSizeGrams": 1000,
    "oilsTotalGrams": 700,
    "oils": [
      {"id": "oil-1", "name": "Olive Oil", "grams": 350, "percent": 50.0},
      {"id": "oil-2", "name": "Coconut Oil", "grams": 210, "percent": 30.0},
      {"id": "oil-3", "name": "Palm Oil", "grams": 140, "percent": 20.0}
    ],
    "lye": {"name": "Sodium Hydroxide", "grams": 100},
    "water": {"name": "Distilled Water", "grams": 200},
    "superfatPercent": 5.0
  },
  "steps": [
    {
      "id": "step-1",
      "kind": "checklist",
      "title": "Sanitize Equipment",
      "description": "Clean and sanitize all equipment before starting",
      "order": 1,
      "status": "todo",
      "items": [
        {"id": "item-1", "label": "Stainless steel pot", "done": false},
        {"id": "item-2", "label": "Stick blender", "done": false}
      ]
    },
    {
      "id": "step-2",
      "kind": "instruction",
      "title": "Prepare Lye Solution",
      "description": "Carefully mix lye with water. Always add lye to water, never reverse.",
      "order": 2,
      "status": "todo"
    }
  ],
  "notes": null,
  "archived": false
}''';
  }

  String _getSampleCreamJson() {
    final now = DateTime.now();
    return '''{
  "id": "sample-cream-${now.microsecondsSinceEpoch}",
  "createdAt": "${now.toIso8601String()}",
  "recipe": {
    "id": "recipe-cream-sample",
    "kind": "cream",
    "name": "Basic Emulsifying Cream",
    "defaultBatchSizeGrams": 500
  },
  "batchCode": "CREAM-SAMPLE",
  "formula": {
    "batchSizeGrams": 500,
    "phases": [
      {
        "id": "phase-a",
        "name": "Water phase",
        "order": 1,
        "totalGrams": 300,
        "items": [
          {"id": "item-1", "name": "Distilled Water", "grams": 250, "percent": 50.0},
          {"id": "item-2", "name": "Glycerin", "grams": 30, "percent": 6.0, "notes": "Humectant"},
          {"id": "item-3", "name": "Aloe Vera Gel", "grams": 20, "percent": 4.0, "notes": "Optional"}
        ]
      },
      {
        "id": "phase-b",
        "name": "Oil phase",
        "order": 2,
        "totalGrams": 180,
        "items": [
          {"id": "item-4", "name": "Emulsifying Wax", "grams": 50, "percent": 10.0, "notes": "Primary emulsifier"},
          {"id": "item-5", "name": "Shea Butter", "grams": 60, "percent": 12.0},
          {"id": "item-6", "name": "Jojoba Oil", "grams": 40, "percent": 8.0},
          {"id": "item-7", "name": "Coconut Oil", "grams": 30, "percent": 6.0}
        ]
      },
      {
        "id": "phase-c",
        "name": "Cooldown",
        "order": 3,
        "totalGrams": 20,
        "items": [
          {"id": "item-8", "name": "Preservative", "grams": 10, "percent": 2.0, "notes": "Add below 40°C"},
          {"id": "item-9", "name": "Fragrance Oil", "grams": 10, "percent": 2.0, "notes": "Optional"}
        ]
      }
    ]
  },
  "steps": [
    {
      "id": "step-1",
      "kind": "checklist",
      "title": "Prepare Equipment",
      "description": "Gather all equipment and ingredients",
      "order": 1,
      "status": "todo",
      "items": [
        {"id": "item-1", "label": "Double boiler", "done": false},
        {"id": "item-2", "label": "Digital scale", "done": false},
        {"id": "item-3", "label": "Stick blender", "done": false}
      ]
    },
    {
      "id": "step-2",
      "kind": "instruction",
      "title": "Weigh Phase A",
      "description": "Weigh all Phase A (water phase) ingredients into a heat-safe container",
      "order": 2,
      "status": "todo"
    },
    {
      "id": "step-3",
      "kind": "instruction",
      "title": "Heat Phase B",
      "description": "Heat Phase B (oil phase) ingredients in double boiler until emulsifying wax is melted (70-75°C)",
      "order": 3,
      "status": "todo"
    },
    {
      "id": "step-4",
      "kind": "instruction",
      "title": "Emulsify",
      "description": "Heat Phase A to 70-75°C. Slowly pour Phase A into Phase B while blending. Continue blending until smooth and creamy",
      "order": 4,
      "status": "todo"
    },
    {
      "id": "step-5",
      "kind": "instruction",
      "title": "Cooldown Additions",
      "description": "Allow to cool to below 40°C, then add Phase C (cooldown) ingredients. Mix gently",
      "order": 5,
      "status": "todo"
    }
  ],
  "notes": null,
  "archived": false
}''';
  }
}
