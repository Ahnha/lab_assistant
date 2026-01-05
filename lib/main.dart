import 'package:flutter/material.dart';
import 'package:skin_studio_design_tokens/design_tokens.dart';
import 'app/main_screen.dart';
import 'app/app_settings_controller.dart';
import 'data/storage_init.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage on startup (must complete before app starts)
  await StorageInit.initialize();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AppSettingsController _settingsController = AppSettingsController();

  @override
  void initState() {
    super.initState();
    _settingsController.load();
    _settingsController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    _settingsController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsController.isLoading) {
      return MaterialApp(
        title: 'Lab Assistant',
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final settings = _settingsController.settings;
    final theme = buildSkinStudioTheme(
      themeKey: settings.themeKey,
      textScale: settings.textScale,
      spacingScale: settings.spacingScale,
    );

    return MaterialApp(
      title: 'Lab Assistant',
      theme: theme,
      home: MainScreen(
        settingsController: _settingsController,
      ),
    );
  }
}
