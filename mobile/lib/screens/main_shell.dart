import 'package:flutter/material.dart';
import 'daily_worship_screen.dart';
import 'adhkar_library_screen.dart';
import 'misbaha_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import '../core/constants/constants.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DailyWorshipScreen(),
    AdhkarLibraryScreen(),
    MisbahaScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppConstants.primaryContainer.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt, color: AppConstants.primary),
            label: 'الورد اليومي',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppConstants.primary),
            label: 'الأذكار',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined),
            selectedIcon: Icon(Icons.touch_app, color: AppConstants.primary),
            label: 'المسبحة',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events, color: AppConstants.primary),
            label: 'المتصدرون',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppConstants.primary),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
