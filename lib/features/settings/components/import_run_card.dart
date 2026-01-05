import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../ui/spacing.dart';
import '../../../app/widgets/primary_button.dart';

/// Card component for importing runs from JSON.
/// Includes textarea, import button, paste from clipboard action.
class ImportRunCard extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onImport;
  final String? helperText;
  final List<String>? errorMessages;
  final double? spacingScale;

  const ImportRunCard({
    super.key,
    this.controller,
    this.onImport,
    this.helperText,
    this.errorMessages,
    this.spacingScale,
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
    final scale = spacingScale ?? 1.0;
    return Column(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (helperText != null) ...[
                    SizedBox(height: LabSpacing.gapXs(scale)),
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
        SizedBox(height: LabSpacing.gapLg(scale)),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 10,
          decoration: InputDecoration(
            hintText: 'Paste JSON data here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
        if (errorMessages != null && errorMessages!.isNotEmpty) ...[
          SizedBox(height: LabSpacing.gapLg(scale)),
          Container(
            padding: EdgeInsets.all(LabSpacing.gapMd(scale)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
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
                    SizedBox(width: LabSpacing.gapSm(scale)),
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
                  SizedBox(height: LabSpacing.gapSm(scale)),
                  ...errorMessages!.map(
                    (error) => Padding(
                      padding: EdgeInsets.only(
                        left: LabSpacing.gapXxxl(scale),
                        top: LabSpacing.gapXs(scale),
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
        SizedBox(height: LabSpacing.gapLg(scale)),
        PrimaryButton(
          label: 'Import',
          icon: Icons.upload_file,
          onPressed: onImport,
        ),
      ],
    );
  }
}
