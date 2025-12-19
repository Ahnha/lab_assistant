import 'package:flutter/services.dart';

/// Lightweight input formatter that restricts input to:
/// - Digits (0-9)
/// - One decimal point (.)
/// - Up to 2 decimal places
/// Does NOT auto-format the value, only restricts input.
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty string
    if (text.isEmpty) {
      return newValue;
    }

    // Check if it's a valid decimal number pattern
    // Allow: digits, one decimal point, up to 2 decimal places
    final regex = RegExp(r'^\d*\.?\d{0,2}$');

    if (regex.hasMatch(text)) {
      return newValue;
    }

    // If not matching, return old value to prevent invalid input
    return oldValue;
  }
}
