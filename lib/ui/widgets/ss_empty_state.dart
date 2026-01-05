import 'package:flutter/material.dart';
import '../spacing.dart';

/// Empty state widget with icon, title, subtitle, and optional CTA button.
/// Designed for polished, actionable empty states.
class SsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryCtaPressed;
  final double? spacingScale;

  const SsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
    this.secondaryCtaLabel,
    this.onSecondaryCtaPressed,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;

    return Center(
      child: Padding(
        padding: LabSpacing.pageInsets(scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56 * scale,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            SizedBox(height: LabSpacing.gapXxl(scale)),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: LabSpacing.gapSm(scale)),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null || secondaryCtaLabel != null) ...[
              SizedBox(height: LabSpacing.gapXxl(scale)),
              if (ctaLabel != null)
                FilledButton.icon(
                  onPressed: onCtaPressed,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(ctaLabel!),
                ),
              if (secondaryCtaLabel != null) ...[
                SizedBox(height: LabSpacing.gapSm(scale)),
                TextButton.icon(
                  onPressed: onSecondaryCtaPressed,
                  icon: const Icon(Icons.paste, size: 18),
                  label: Text(secondaryCtaLabel!),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
