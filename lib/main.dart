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
    final baseTheme = buildSkinStudioTheme(
      themeKey: settings.themeKey,
      textScale: settings.textScale,
      spacingScale: settings.spacingScale,
    );

    // Apply iOS-like polish to the theme
    final theme = baseTheme.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: baseTheme.colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: baseTheme.colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: baseTheme.colorScheme.outline.withOpacity(0.12),
        thickness: 0.5,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: baseTheme.colorScheme.surface,
        foregroundColor: baseTheme.colorScheme.onSurface,
        titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: baseTheme.colorScheme.surface,
        indicatorColor: baseTheme.colorScheme.primaryContainer.withOpacity(0.3),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return baseTheme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: baseTheme.colorScheme.onSurface,
            );
          }
          return baseTheme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: baseTheme.colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              size: 24,
              color: baseTheme.colorScheme.onSurface,
            );
          }
          return IconThemeData(
            size: 24,
            color: baseTheme.colorScheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return baseTheme.colorScheme.primary;
          }
          return baseTheme.colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return baseTheme.colorScheme.primaryContainer;
          }
          return baseTheme.colorScheme.surfaceContainerHighest;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseTheme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseTheme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseTheme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseTheme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseTheme.colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          color: baseTheme.colorScheme.onSurfaceVariant,
        ),
        labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
        ),
      ),
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
