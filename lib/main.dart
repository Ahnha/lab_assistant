import 'package:flutter/material.dart';
import 'app/app_theme.dart';
import 'app/main_screen.dart';
import 'data/app_settings.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _labModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLabModeSetting();
  }

  Future<void> _loadLabModeSetting() async {
    final enabled = await AppSettings.isLabModeEnabled();
    if (mounted) {
      setState(() {
        _labModeEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply textScaleFactor when Lab Mode is enabled
    final textScaleFactor = _labModeEnabled ? 1.15 : 1.0;
    return MaterialApp(
      title: 'Lab Assistant',
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaleFactor: textScaleFactor),
          child: child!,
        );
      },
      home: MainScreen(onSettingsChanged: _loadLabModeSetting),
    );
  }
}
