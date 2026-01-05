import 'package:flutter/material.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/run/history_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_settings_controller.dart';

class MainScreen extends StatefulWidget {
  final AppSettingsController settingsController;

  const MainScreen({super.key, required this.settingsController});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildInboxScreen(BuildContext context) {
    // Use the responsive InboxScreen which handles both mobile and desktop
    return InboxScreen(
      settingsController: widget.settingsController,
      onNavigateToTab: _goToTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildInboxScreen(context)
          : _currentIndex == 1
              ? HistoryScreen(
                  settingsController: widget.settingsController,
                  onNavigateToTab: _goToTab,
                )
              : SettingsScreen(settingsController: widget.settingsController),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined, size: 24),
              selectedIcon: Icon(Icons.inbox, size: 24),
              label: 'Inbox',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, size: 24),
              selectedIcon: Icon(Icons.history, size: 24),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, size: 24),
              selectedIcon: Icon(Icons.settings, size: 24),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
