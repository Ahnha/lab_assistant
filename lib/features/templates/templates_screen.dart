import 'package:flutter/material.dart';
import 'dart:convert';
import '../../domain/recipe_template.dart';
import '../../data/recipe_template_repository.dart';
import '../../utils/date_formatter.dart';
import '../../app/ui_tokens.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/secondary_button.dart';
import '../../widgets/recipe_badge.dart';
import '../../domain/template_to_run_converter.dart';
import '../../domain/lab_run.dart';
import '../../domain/lab_run_parser.dart';
import '../../domain/lab_run_validator.dart';
import '../../domain/lab_run_to_template_converter.dart';
import '../../data/lab_run_repository.dart';
import '../../app/log.dart';
import '../run/run_detail_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final RecipeTemplateRepository _templateRepo = RecipeTemplateRepository();
  final LabRunRepository _runRepo = LabRunRepository();
  final TextEditingController _jsonController = TextEditingController();
  List<RecipeTemplate> _templates = [];
  bool _isLoading = true;
  List<String> _errorMessages = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });
    final templates = await _templateRepo.loadAllTemplates();
    // Sort: system templates first, then user templates, both by name
    templates.sort((a, b) {
      if (a.isSystem != b.isSystem) {
        return a.isSystem ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  Future<void> _startRunFromTemplate(RecipeTemplate template) async {
    try {
      Log.d('TemplatesScreen', 'Starting run from template: ${template.id}');
      final run = TemplateToRunConverter.createRunFromTemplate(template);
      Log.d(
        'TemplatesScreen',
        'Run started: ${run.id} from template: ${template.id}',
      );
      await _runRepo.save(run);
      Log.d('TemplatesScreen', 'Run created: ${run.id}');

      if (!mounted) return;

      // Navigate to run detail screen
      await Navigator.push<LabRun>(
        context,
        MaterialPageRoute(builder: (context) => RunDetailScreen(run: run)),
      );

      // Refresh templates in case we need to
      _loadTemplates();
    } catch (e) {
      Log.d('TemplatesScreen', 'Failed to start run: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start run: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importTemplate() async {
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
      Log.d('TemplatesScreen', 'Import template started');
      // Parse as LabRun first, then convert to template
      final run = LabRunParser.parse(jsonText);

      // Validator returns friendly error messages for UI display
      final validationErrors = LabRunValidator.validate(run);
      if (validationErrors.isNotEmpty) {
        setState(() {
          _errorMessages = validationErrors;
        });
        Log.d(
          'TemplatesScreen',
          'Import validation failed: ${validationErrors.join(", ")}',
        );
        return;
      }

      // Convert to template
      final template = LabRunToTemplateConverter.createTemplateFromRun(run);
      await _templateRepo.save(template);
      Log.d('TemplatesScreen', 'Template imported: ${template.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template imported successfully')),
        );
        _jsonController.clear();
        _loadTemplates();
      }
    } catch (e) {
      Log.d('TemplatesScreen', 'Import failure: $e');
      setState(() {
        _errorMessages = ['Failed to import: ${e.toString()}'];
      });
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paste JSON data to import as a template:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _jsonController,
                  maxLines: 10,
                  minLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Paste JSON data here',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
                if (_errorMessages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: UITokens.paddingM,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: UITokens.borderRadiusS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessages.length == 1
                                    ? _errorMessages.first
                                    : 'Found ${_errorMessages.length} errors:',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessages.length > 1) ...[
                          const SizedBox(height: UITokens.spacingS),
                          ..._errorMessages.map(
                            (error) => Padding(
                              padding: const EdgeInsets.only(
                                left: UITokens.spacingXXXL,
                                top: UITokens.spacingXS,
                              ),
                              child: Text(
                                '• $error',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          SecondaryButton(
            label: 'Cancel',
            onPressed: () {
              _jsonController.clear();
              setState(() {
                _errorMessages = [];
              });
              Navigator.of(context).pop();
            },
            isFullWidth: false,
          ),
          PrimaryButton(
            label: 'Import Template',
            icon: Icons.upload_file,
            onPressed: () async {
              await _importTemplate();
              if (mounted && _errorMessages.isEmpty) {
                Navigator.of(context).pop();
              }
            },
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(RecipeTemplate template) async {
    if (template.isSystem) {
      // Don't allow deleting system templates
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System templates cannot be deleted')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _templateRepo.delete(template.id);
      _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Template deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import template',
            onPressed: _showImportDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTemplates,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  return _buildTemplateTile(_templates[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Templates will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateTile(RecipeTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                template.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RecipeBadge(kind: template.kind),
            if (template.isSystem) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.verified,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${template.steps.length} steps',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (template.isSystem) ...[
                const SizedBox(height: 4),
                Text(
                  'System template',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start run',
              onPressed: () => _startRunFromTemplate(template),
            ),
            if (!template.isSystem)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete template',
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _deleteTemplate(template),
              ),
          ],
        ),
      ),
    );
  }
}
