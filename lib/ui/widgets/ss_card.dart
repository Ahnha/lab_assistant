import 'package:flutter/material.dart';
import '../spacing.dart';

/// A consistent Card wrapper with iOS-like styling:
/// - Rounded corners (18-22)
/// - 0 elevation
/// - Subtle border using theme divider color at low opacity
/// - Consistent internal padding
class SsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final double? spacingScale;

  const SsCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;
    final radius = borderRadius ?? 20.0;
    final cardPadding = padding ?? LabSpacing.cardInsets(scale);
    final cardMargin = margin ?? EdgeInsets.only(bottom: LabSpacing.gapMd(scale));

    return Container(
      margin: cardMargin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: cardPadding,
        child: child,
      ),
    );
  }
}
