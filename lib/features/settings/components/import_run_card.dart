import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/ui_tokens.dart';
import '../../../app/widgets/primary_button.dart';

/// Card component for importing runs from JSON.
/// Includes textarea, import button, paste from clipboard action.
class ImportRunCard extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onImport;
  final String? helperText;
  final List<String>? errorMessages;

  const ImportRunCard({
    super.key,
    this.controller,
    this.onImport,
    this.helperText,
    this.errorMessages,
  });

  Future<void> _pasteFromClipboard(
    BuildContext context,
    TextEditingController? controller,
  ) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && controller != null) {
      controller.text = clipboardData!.text!;
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text found in clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: UITokens.elevationLow,
      child: Padding(
        padding: UITokens.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Run',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (helperText != null) ...[
                        const SizedBox(height: UITokens.spacingXS),
                        Text(
                          helperText!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: controller != null
                      ? () => _pasteFromClipboard(context, controller)
                      : null,
                  icon: const Icon(Icons.paste, size: 18),
                  label: const Text('Paste from clipboard'),
                ),
              ],
            ),
            const SizedBox(height: UITokens.spacingL),
            TextField(
              controller: controller,
              maxLines: null,
              minLines: 10,
              decoration: InputDecoration(
                hintText: 'Paste JSON data here',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
            if (errorMessages != null && errorMessages!.isNotEmpty) ...[
              const SizedBox(height: UITokens.spacingL),
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
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: UITokens.spacingS),
                        Expanded(
                          child: Text(
                            errorMessages!.length == 1
                                ? errorMessages!.first
                                : 'Found ${errorMessages!.length} errors:',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorMessages!.length > 1) ...[
                      const SizedBox(height: UITokens.spacingS),
                      ...errorMessages!.map(
                        (error) => Padding(
                          padding: const EdgeInsets.only(
                            left: UITokens.spacingXXXL,
                            top: UITokens.spacingXS,
                          ),
                          child: Text(
                            '• $error',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: UITokens.spacingL),
            PrimaryButton(
              label: 'Import',
              icon: Icons.upload_file,
              onPressed: onImport,
            ),
          ],
        ),
      ),
    );
  }
}
