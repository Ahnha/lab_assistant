import 'package:flutter/material.dart';
import '../ui_tokens.dart';

/// Secondary action button with consistent styling.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: TextButton.styleFrom(
              padding: UITokens.paddingM,
              shape: RoundedRectangleBorder(
                borderRadius: UITokens.borderRadiusM,
              ),
            ),
          )
        : TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: UITokens.paddingM,
              shape: RoundedRectangleBorder(
                borderRadius: UITokens.borderRadiusM,
              ),
            ),
            child: Text(label),
          );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
