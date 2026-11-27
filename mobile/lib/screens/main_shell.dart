import 'dart:async';
import 'package:flutter/material.dart';
import 'daily_worship_screen.dart';
import 'prayer_times_screen.dart';
import 'adhkar_library_screen.dart';
import 'misbaha_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'qibla_screen.dart';
import '../core/constants/constants.dart';
import '../main.dart';
import '../services/notification_service.dart';
import '../services/azan_audio_service.dart';
import '../services/app_update_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<MisbahaScreenState> _misbahaKey = GlobalKey<MisbahaScreenState>();
  StreamSubscription<String>? _notifSub;

  late final List<Widget> _screens = [
    const DailyWorshipScreen(),
    const PrayerTimesScreen(),
    const AdhkarLibraryScreen(),
    MisbahaScreen(key: _misbahaKey),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _notifSub = NotificationService.instance.onNotificationTap.listen(_handleNotificationPayload);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = NotificationService.instance.initialLaunchPayload;
      if (initial != null && initial.isNotEmpty) {
        NotificationService.instance.initialLaunchPayload = null;
        _handleNotificationPayload(initial);
      } else {
        final nativeTab = await NotificationService.instance.consumeInitialNativeTab();
        if (nativeTab != null && nativeTab.isNotEmpty) {
          _handleNotificationPayload('open:$nativeTab');
        }
      }
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.updateOngoingPrayerNotification();
      _checkForAppUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.updateOngoingPrayerNotification();
    }
  }

  Future<void> _handleNotificationPayload(String payload) async {
    if (!mounted) return;
    // Pop any pushed sub-routes (e.g., HijriCalendarScreen, AuthScreen) back to MainShell
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (payload == 'misbaha:morning' || payload == 'misbaha:evening') {
      final mode = payload.split(':').last;
      setState(() => _currentIndex = 3);
      // Ensure MisbahaScreen state switches mode immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _misbahaKey.currentState?.openFromNotification(mode);
      });
    } else if (payload == 'open:prayers') {
      setState(() => _currentIndex = 1);
    } else if (payload == 'open:qibla') {
      setState(() => _currentIndex = 1);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QiblaScreen()),
      );
    } else if (payload.startsWith('prayer:')) {
      final key = payload.substring('prayer:'.length);
      setState(() => _currentIndex = 1);
      final mode = await NotificationService.instance.getPrayerSoundMode();
      if (key != 'sunrise' && mode != 'silent' && mode != 'default') {
        await AzanAudioService.instance.playSoundKey(mode);
      }
    }
  }

  Future<void> _checkForAppUpdates() async {
    final update = await AppUpdateService.instance.checkForUpdate();
    if (update != null && mounted) {
      await AppUpdateService.instance.showUpdateDialog(context, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIconColor = AppConstants.accent(context);
    final inactiveIconColor = AppConstants.textSecondary(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppConstants.isDark(context) ? AppConstants.cardDark : null,
        indicatorColor: AppConstants.isDark(context)
            ? Colors.white.withOpacity(0.14)
            : AppConstants.primaryContainer.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined, color: inactiveIconColor),
            selectedIcon: Icon(Icons.task_alt, color: activeIconColor),
            label: 'الورد',
          ),
          NavigationDestination(
            icon: Icon(Icons.mosque_outlined, color: inactiveIconColor),
            selectedIcon: Icon(Icons.mosque, color: activeIconColor),
            label: 'الأذان',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: inactiveIconColor),
            selectedIcon: Icon(Icons.menu_book, color: activeIconColor),
            label: 'الأذكار',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined, color: inactiveIconColor),
            selectedIcon: Icon(Icons.touch_app, color: activeIconColor),
            label: 'المسبحة',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined, color: inactiveIconColor),
            selectedIcon: Icon(Icons.emoji_events, color: activeIconColor),
            label: 'المتصدرون',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: inactiveIconColor),
            selectedIcon: Icon(Icons.person, color: activeIconColor),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
