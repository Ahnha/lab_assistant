import 'package:flutter/material.dart';
import 'spacing.dart';

/// ConstrainedPage widget that centers content on wide screens.
/// On mobile, uses full width with padding.
/// On desktop/web, centers content with max width (980px) and responsive padding.
class ConstrainedPage extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? spacingScale;

  const ConstrainedPage({
    super.key,
    required this.child,
    this.maxWidth = 980.0,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final scale = spacingScale ?? 1.0;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // On mobile (< 600px), use full width with padding
    // On tablet/desktop, center with max width
    if (screenWidth < 600) {
      return Padding(
        padding: LabSpacing.pageInsets(scale),
        child: child,
      );
    }

    // On wider screens, center content
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 980.0,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < 900 ? LabSpacing.gapLg(scale) : LabSpacing.gapXxl(scale),
          ),
          child: child,
        ),
      ),
    );
  }
}
