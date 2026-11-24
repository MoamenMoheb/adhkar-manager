import 'package:flutter/material.dart';
import 'daily_worship_screen.dart';
import 'prayer_times_screen.dart';
import 'adhkar_library_screen.dart';
import 'misbaha_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import '../core/constants/constants.dart';
import '../services/notification_service.dart';
import '../services/azan_audio_service.dart';
import '../services/app_update_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DailyWorshipScreen(),
    PrayerTimesScreen(),
    AdhkarLibraryScreen(),
    MisbahaScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (NotificationService.instance.pendingMisbahaMode.value != null) {
      _currentIndex = 3; // Misbaha tab
    } else if (NotificationService.instance.pendingPrayerKey.value != null) {
      _currentIndex = 1; // Prayer/Azan tab
      NotificationService.instance.pendingPrayerKey.value = null;
    }
    NotificationService.instance.pendingMisbahaMode.addListener(_onPendingMisbaha);
    NotificationService.instance.pendingPrayerKey.addListener(_onPendingPrayer);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForAppUpdates());
  }

  Future<void> _checkForAppUpdates() async {
    final update = await AppUpdateService.instance.checkForUpdate();
    if (update != null && mounted) {
      await AppUpdateService.instance.showUpdateDialog(context, update);
    }
  }

  @override
  void dispose() {
    NotificationService.instance.pendingMisbahaMode.removeListener(_onPendingMisbaha);
    NotificationService.instance.pendingPrayerKey.removeListener(_onPendingPrayer);
    super.dispose();
  }

  void _onPendingMisbaha() {
    if (NotificationService.instance.pendingMisbahaMode.value != null && mounted) {
      setState(() => _currentIndex = 3);
    }
  }

  Future<void> _onPendingPrayer() async {
    final key = NotificationService.instance.pendingPrayerKey.value;
    if (key != null && mounted) {
      NotificationService.instance.pendingPrayerKey.value = null;
      setState(() => _currentIndex = 1);
      final mode = await NotificationService.instance.getPrayerSoundMode();
      if (key != 'sunrise' && mode == 'azan') {
        await AzanAudioService.instance.playAzan(shortTakbeer: false);
      } else if (mode == 'takbeer') {
        await AzanAudioService.instance.playAzan(shortTakbeer: true);
      }
    }
  }

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
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt, color: AppConstants.primary),
            label: 'الورد',
          ),
          NavigationDestination(
            icon: Icon(Icons.mosque_outlined),
            selectedIcon: Icon(Icons.mosque, color: AppConstants.primary),
            label: 'الأذان',
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
