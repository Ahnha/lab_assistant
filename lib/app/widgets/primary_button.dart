import 'package:flutter/material.dart';
import '../ui_tokens.dart';

/// Primary action button with consistent styling.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: backgroundColor != null
                ? FilledButton.styleFrom(
                    backgroundColor: backgroundColor,
                    padding: UITokens.paddingL,
                    shape: RoundedRectangleBorder(
                      borderRadius: UITokens.borderRadiusM,
                    ),
                    minimumSize: isFullWidth
                        ? const Size(double.infinity, 48)
                        : null,
                  )
                : FilledButton.styleFrom(
                    padding: UITokens.paddingL,
                    shape: RoundedRectangleBorder(
                      borderRadius: UITokens.borderRadiusM,
                    ),
                    minimumSize: isFullWidth
                        ? const Size(double.infinity, 48)
                        : null,
                  ),
          )
        : FilledButton(
            onPressed: onPressed,
            style: backgroundColor != null
                ? FilledButton.styleFrom(
                    backgroundColor: backgroundColor,
                    padding: UITokens.paddingL,
                    shape: RoundedRectangleBorder(
                      borderRadius: UITokens.borderRadiusM,
                    ),
                    minimumSize: isFullWidth
                        ? const Size(double.infinity, 48)
                        : null,
                  )
                : FilledButton.styleFrom(
                    padding: UITokens.paddingL,
                    shape: RoundedRectangleBorder(
                      borderRadius: UITokens.borderRadiusM,
                    ),
                    minimumSize: isFullWidth
                        ? const Size(double.infinity, 48)
                        : null,
                  ),
            child: Text(label),
          );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
