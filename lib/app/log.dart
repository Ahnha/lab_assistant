import 'package:flutter/foundation.dart';

/// Simple debug logging utility.
/// Only logs in debug mode to avoid performance impact in release builds.
class Log {
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[LabAssistant/$tag] $message');
    }
  }
}
