import 'package:flutter/material.dart';
import 'spacing.dart';
import 'branded_header.dart';
import 'layout.dart';

/// Premium iOS-like page scaffold wrapper.
/// Provides SafeArea, consistent padding, max content width on desktop,
/// subtle background, and branded header.
class PageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final double? maxWidth;
  final double? spacingScale;
  final bool scrollable;
  final Color? backgroundColor;

  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.maxWidth = 920.0,
    this.spacingScale,
    this.scrollable = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = spacingScale ?? 1.0;
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandedHeader(
          title: title,
          spacingScale: scale,
          trailing: trailing,
        ),
        Expanded(
          child: ConstrainedPage(
            spacingScale: scale,
            maxWidth: maxWidth,
            child: scrollable
                ? SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: LabSpacing.gapXxl(scale),
                      ),
                      child: child,
                    ),
                  )
                : child,
          ),
        ),
      ],
    );

    return Container(
      color: bgColor,
      child: content,
    );
  }
}
