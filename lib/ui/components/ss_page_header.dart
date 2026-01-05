import 'package:flutter/material.dart';
import '../spacing.dart';

/// Premium iOS-like page header with logo, brand text, and page title.
/// Centered on mobile, constrained on wide screens.
class SsPageHeader extends StatelessWidget {
  final String title;
  final String brandText;
  final bool showLogo;
  final double? maxWidth;
  final double? spacingScale;

  const SsPageHeader({
    super.key,
    required this.title,
    this.brandText = 'Skin Studio.',
    this.showLogo = true,
    this.maxWidth = 840,
    this.spacingScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;
    final effectiveMaxWidth = maxWidth ?? 840;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: EdgeInsets.only(
            top: LabSpacing.gapXxl(scale),
            bottom: LabSpacing.gapLg(scale),
            left: LabSpacing.gapLg(scale),
            right: LabSpacing.gapLg(scale),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo and brand row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showLogo) ...[
                    Image.asset(
                      'assets/images/logo.png',
                      width: 36 * scale,
                      height: 36 * scale,
                      filterQuality: FilterQuality.high,
                    ),
                    SizedBox(width: LabSpacing.gapSm(scale)),
                  ],
                  Text(
                    brandText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17 * scale,
                      letterSpacing: 0.3,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: LabSpacing.gapLg(scale)),
              // Page title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 30 * scale,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
