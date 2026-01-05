import 'package:flutter/material.dart';
import '../../../ui/spacing.dart';

/// Reusable toggle row for settings screens.
/// Displays label and description on the left, switch on the right.
class SettingsToggleRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? spacingScale;

  const SettingsToggleRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final scale = spacingScale ?? 1.0;
    return Padding(
      padding: LabSpacing.tileInsets(scale),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (description != null) ...[
                  SizedBox(height: LabSpacing.gapXs(scale)),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: LabSpacing.gapLg(scale)),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
