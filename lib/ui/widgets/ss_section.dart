import 'package:flutter/material.dart';
import '../spacing.dart';
import 'ss_card.dart';

/// A "section header + grouped card" widget for Settings (like iOS grouped style).
/// Provides a section title and groups child widgets in a card.
class SsSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacingScale;

  const SsSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.padding,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: LabSpacing.gapLg(scale),
            top: LabSpacing.gapXxl(scale),
            bottom: LabSpacing.gapSm(scale),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              if (description != null) ...[
                SizedBox(height: LabSpacing.gapXs(scale)),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        SsCard(
          spacingScale: scale,
          padding: EdgeInsets.zero,
          child: Column(
            children: _buildChildrenWithDividers(context, scale),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context, double scale) {
    if (children.isEmpty) return [];
    if (children.length == 1) return children;

    final result = <Widget>[];
    final theme = Theme.of(context);

    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outline.withOpacity(0.12),
            indent: LabSpacing.gapLg(scale),
            endIndent: LabSpacing.gapLg(scale),
          ),
        );
      }
    }

    return result;
  }
}
