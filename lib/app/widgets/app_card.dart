import 'package:flutter/material.dart';
import '../ui_tokens.dart';

/// Reusable card widget with consistent styling.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? UITokens.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: UITokens.borderRadiusM,
        child: Padding(padding: padding ?? UITokens.paddingL, child: child),
      ),
    );
  }
}
