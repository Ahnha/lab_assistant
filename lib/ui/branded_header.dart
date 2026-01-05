import 'package:flutter/material.dart';
import 'spacing.dart';

/// Premium iOS-like branded header component.
/// Shows lab logo + "Lab Assistant" brand text, followed by page title.
/// Centered, spacious, minimalist design.
class BrandedHeader extends StatelessWidget {
  final String title;
  final String brandText;
  final bool showLogo;
  final double? spacingScale;
  final Widget? trailing;

  const BrandedHeader({
    super.key,
    required this.title,
    this.brandText = 'Lab Assistant',
    this.showLogo = true,
    this.spacingScale,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(
          top: LabSpacing.gapXxl(scale),
          bottom: LabSpacing.gapLg(scale),
          left: LabSpacing.gapLg(scale),
          right: LabSpacing.gapLg(scale),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand row: logo + "Lab Assistant" (centered as a group)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showLogo) ...[
                  Image.asset(
                    'assets/images/lab_logo.png',
                    height: 18 * scale,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  SizedBox(width: LabSpacing.gapSm(scale)),
                ],
                Text(
                  brandText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16 * scale,
                    letterSpacing: 0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: LabSpacing.gapMd(scale)),
            // Page title (centered, large headline)
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 36 * scale,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ) ??
                  theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 36 * scale,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
