import 'package:flutter/material.dart';
import '../../../app/ui_tokens.dart';

/// Reusable section container for settings screens.
/// Provides consistent card-like styling with title and optional description.
class SettingsSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final EdgeInsets? padding;

  const SettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: UITokens.elevationLow,
      child: Padding(
        padding: padding ?? UITokens.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (description != null) ...[
              const SizedBox(height: UITokens.spacingXS),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: UITokens.spacingL),
            child,
          ],
        ),
      ),
    );
  }
}
