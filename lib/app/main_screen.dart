import 'package:flutter/material.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/inbox/inbox_master_detail_screen.dart';
import '../features/run/history_screen.dart';
import '../features/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const MainScreen({super.key, this.onSettingsChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _buildInboxScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use master/detail layout for tablets (width >= 900dp)
    if (screenWidth >= 900) {
      return const InboxMasterDetailScreen();
    }
    // Use regular navigation for phones
    return const InboxScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildInboxScreen(context)
          : _currentIndex == 1
          ? const HistoryScreen()
          : SettingsScreen(onSettingsChanged: widget.onSettingsChanged),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
