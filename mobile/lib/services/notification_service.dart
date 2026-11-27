import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../core/utils/hijri_calendar.dart';
import '../core/utils/sun_times.dart';
import '../core/utils/prayer_times.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  static const MethodChannel _stickyChannel =
      MethodChannel('com.moamenmoheb.adhkar_sanctuary/sticky_prayer');

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Timer? _ongoingRefreshTimer;

  /// Live state notifier so switches stay in sync across screens.
  final ValueNotifier<bool> fixedPrayerNotifNotifier = ValueNotifier<bool>(true);

  /// Payload captured on cold-launch from a notification tap.
  String? initialLaunchPayload;

  /// Broadcast stream for notification taps while app is running or in background.
  final StreamController<String> _tapStreamController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _tapStreamController.stream;

  static const String _prefMonThuEnabled = 'notif_mon_thu_enabled';
  static const String _prefAyyamBeedEnabled = 'notif_ayyam_beed_enabled';
  static const String _prefMorningAdhkarEnabled = 'notif_morning_adhkar_enabled';
  static const String _prefEveningAdhkarEnabled = 'notif_evening_adhkar_enabled';
  static const String _prefMorningAdhkarOffsetMin = 'notif_morning_adhkar_offset_min';
  static const String _prefEveningAdhkarOffsetMin = 'notif_evening_adhkar_offset_min';
  static const String _prefFixedPrayerNotif = 'notif_fixed_prayer_enabled';
  static const String _prefEveningHour = 'notif_evening_hour';
  static const String _prefEveningMinute = 'notif_evening_minute';
  static const String _prefHijriOffset = 'hijri_date_offset';
  static const String _prefCityKey = 'sun_times_city_key';
  static const String _prefPrayerSoundMode = 'prayer_sound_mode';
  static const String _prefPrayerMethodKey = 'prayer_method_key';
  static const String _prefHanafiAsr = 'prayer_hanafi_asr';

  static const int _ongoingPrayerNotifId = 8888;
  static const String _ongoingChannelId = 'adhkar_ongoing_salah_v2';
  static const String _ongoingChannelName = 'إشعار الصلاة القادمة الدائم';
  static const String _ongoingChannelDesc = 'يعرض الصلاة القادمة والعد التنازلي بشكل ثابت في شريط الإشعارات';

  static const String _fastingChannelId = 'adhkar_fasting_reminders';
  static const String _fastingChannelName = 'تذكير صيام التطوع والأيام البيض';
  static const String _fastingChannelDesc = 'تنبيهات تذكيرية لصيام الإثنين والخميس والأيام البيض (١٣، ١٤، ١٥ هجري)';

  static const String _adhkarChannelId = 'adhkar_morning_evening_reminders';
  static const String _adhkarChannelName = 'تذكير أذكار الصباح والمساء';
  static const String _adhkarChannelDesc = 'تنبيهات تلقائية قبل الشروق والمغرب حسب المدة المحددة';

  static const String _prayerAzanChannelId = 'adhkar_prayer_azan_v1';
  static const String _prayerTakbeerChannelId = 'adhkar_prayer_takbeer_v1';
  static const String _prayerDefaultChannelId = 'adhkar_prayer_default_v1';
  static const String _prayerChannelName = 'مواقيت الصلاة والأذان';
  static const String _prayerChannelDesc = 'تنبيهات الصلوات الخمس والشروق بصوت الأذان أو الإشعارات';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapStreamController.add(payload);
        }
      },
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          initialLaunchPayload = payload;
        }
      }
    } catch (e) {
      debugPrint('Launch details check notice: $e');
    }

    _stickyChannel.setMethodCallHandler((call) async {
      if (call.method == 'openedFromSticky') {
        _tapStreamController.add('open:prayers');
      }
    });

    _initialized = true;
    fixedPrayerNotifNotifier.value = await isFixedPrayerNotifEnabled();
    await scheduleAllReminders();
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  Future<bool> isMonThuEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefMonThuEnabled) ?? true;
  }

  Future<bool> isAyyamBeedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAyyamBeedEnabled) ?? true;
  }

  Future<bool> isMorningAdhkarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefMorningAdhkarEnabled) ?? true;
  }

  Future<bool> isEveningAdhkarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEveningAdhkarEnabled) ?? true;
  }

  Future<int> getMorningAdhkarOffsetMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_prefMorningAdhkarOffsetMin) ?? 30).clamp(1, 180);
  }

  Future<int> getEveningAdhkarOffsetMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_prefEveningAdhkarOffsetMin) ?? 30).clamp(1, 180);
  }

  Future<bool> isFixedPrayerNotifEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefFixedPrayerNotif) ?? true;
  }

  Future<void> setFixedPrayerNotifEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefFixedPrayerNotif, enabled);
    fixedPrayerNotifNotifier.value = enabled;
    await updateOngoingPrayerNotification();
  }

  Future<bool> isPrayerNotifEnabled(String prayerKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('prayer_notif_$prayerKey') ?? true;
  }

  Future<void> setPrayerNotifEnabled(String prayerKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_notif_$prayerKey', enabled);
    await scheduleAllReminders();
  }

  Future<String> getPrayerSoundMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefPrayerSoundMode) ?? 'azan';
  }

  Future<void> setPrayerSoundMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPrayerSoundMode, mode);
    await scheduleAllReminders();
  }

  Future<String?> getPrayerMethodKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefPrayerMethodKey);
  }

  Future<void> setPrayerMethodKey(String methodKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPrayerMethodKey, methodKey);
    await scheduleAllReminders();
  }

  Future<bool> isHanafiAsr() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefHanafiAsr) ?? false;
  }

  Future<void> setHanafiAsr(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefHanafiAsr, val);
    await scheduleAllReminders();
  }

  Future<List<int>> getEveningReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_prefEveningHour) ?? 20;
    final minute = prefs.getInt(_prefEveningMinute) ?? 30;
    return [hour, minute];
  }

  Future<int> getHijriOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefHijriOffset) ?? 0;
  }

  Future<String> getSelectedCityKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefCityKey) ?? SunTimesCalculator.defaultCityForLocalTimezone().key;
  }

  Future<void> setSelectedCityKey(String cityKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCityKey, cityKey);
    await scheduleAllReminders();
  }

  Future<void> setHijriOffset(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHijriOffset, offset.clamp(-2, 2));
    await scheduleAllReminders();
  }

  Future<void> updateSettings({
    bool? monThuEnabled,
    bool? ayyamBeedEnabled,
    bool? morningAdhkarEnabled,
    bool? eveningAdhkarEnabled,
    int? morningAdhkarOffsetMin,
    int? eveningAdhkarOffsetMin,
    int? eveningHour,
    int? eveningMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (monThuEnabled != null) await prefs.setBool(_prefMonThuEnabled, monThuEnabled);
    if (ayyamBeedEnabled != null) await prefs.setBool(_prefAyyamBeedEnabled, ayyamBeedEnabled);
    if (morningAdhkarEnabled != null) await prefs.setBool(_prefMorningAdhkarEnabled, morningAdhkarEnabled);
    if (eveningAdhkarEnabled != null) await prefs.setBool(_prefEveningAdhkarEnabled, eveningAdhkarEnabled);
    if (morningAdhkarOffsetMin != null) {
      await prefs.setInt(_prefMorningAdhkarOffsetMin, morningAdhkarOffsetMin.clamp(1, 180));
    }
    if (eveningAdhkarOffsetMin != null) {
      await prefs.setInt(_prefEveningAdhkarOffsetMin, eveningAdhkarOffsetMin.clamp(1, 180));
    }
    if (eveningHour != null) await prefs.setInt(_prefEveningHour, eveningHour);
    if (eveningMinute != null) await prefs.setInt(_prefEveningMinute, eveningMinute);
    await scheduleAllReminders();
  }

  Future<void> scheduleFastingReminders() => scheduleAllReminders();

  String _prayerChannelForMode(String mode) {
    if (mode == 'azan') return _prayerAzanChannelId;
    if (mode == 'takbeer') return _prayerTakbeerChannelId;
    return _prayerDefaultChannelId;
  }

  AndroidNotificationSound? _prayerSoundForMode(String mode) {
    if (mode == 'azan') return const RawResourceAndroidNotificationSound('azan');
    if (mode == 'takbeer') return const RawResourceAndroidNotificationSound('takbeer');
    return null;
  }

  String _fmtTime12(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'م' : 'ص';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  /// Displays / refreshes a pinned non-removable sticky notification showing
  /// the next Salah, its exact time, and a live native Android Chronometer countdown.
  Future<void> updateOngoingPrayerNotification() async {
    if (!_initialized) return;
    try {
      final enabled = await isFixedPrayerNotifEnabled();
      fixedPrayerNotifNotifier.value = enabled;

      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

      if (!enabled) {
        _ongoingRefreshTimer?.cancel();
        _ongoingRefreshTimer = null;
        if (isAndroid) {
          try {
            await _stickyChannel.invokeMethod('stop');
          } catch (e) {
            debugPrint('Sticky channel stop notice: $e');
          }
          final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          await androidImpl?.stopForegroundService();
        }
        await _plugin.cancel(_ongoingPrayerNotifId);
        return;
      }

      final city = SunTimesCalculator.getCityByKey(await getSelectedCityKey());
      final method = PrayerTimesCalculator.getMethodByKey(await getPrayerMethodKey(), cityKey: city.key);
      final hanafi = await isHanafiAsr();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final List<Map<String, dynamic>> upcoming = [];
      for (int i = 0; i <= 10; i++) {
        final dayTimes = PrayerTimesCalculator.calculate(
          date: today.add(Duration(days: i)),
          city: city,
          method: method,
          hanafiAsr: hanafi,
        );
        for (final entry in dayTimes.allEntries) {
          if (entry.time.isAfter(now)) {
            final label = entry.isFardPrayer ? 'صلاة ${entry.nameAr}' : entry.nameAr;
            upcoming.add({
              'key': entry.key,
              'title': label,
              'body': _fmtTime12(entry.time),
              'timeMs': entry.time.millisecondsSinceEpoch,
            });
          }
        }
      }

      if (upcoming.isEmpty) return;

      if (isAndroid) {
        await _stickyChannel.invokeMethod('startOrUpdate', {
          'scheduleJson': jsonEncode(upcoming),
        });
      } else {
        final first = upcoming.first;
        await _plugin.show(
          _ongoingPrayerNotifId,
          first['title'] as String,
          first['body'] as String,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(presentSound: false),
          ),
          payload: 'open:prayers',
        );
      }

      final nextMs = upcoming.first['timeMs'] as int;
      _ongoingRefreshTimer?.cancel();
      final diffMs = nextMs - now.millisecondsSinceEpoch + 2000;
      final safeMs = diffMs < 5000 ? 5000 : diffMs;
      _ongoingRefreshTimer = Timer(Duration(milliseconds: safeMs), () {
        updateOngoingPrayerNotification();
      });
    } catch (e) {
      debugPrint('Failed to update ongoing prayer notification: $e');
    }
  }

  Future<void> scheduleAllReminders() async {
    if (!_initialized) return;

    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        if (req.id != _ongoingPrayerNotifId) {
          await _plugin.cancel(req.id);
        }
      }

      final monThuOn = await isMonThuEnabled();
      final ayyamOn = await isAyyamBeedEnabled();
      final morningAdhkarOn = await isMorningAdhkarEnabled();
      final eveningAdhkarOn = await isEveningAdhkarEnabled();
      final morningOffset = await getMorningAdhkarOffsetMinutes();
      final eveningOffset = await getEveningAdhkarOffsetMinutes();

      final time = await getEveningReminderTime();
      final evHour = time[0];
      final evMinute = time[1];
      final offset = await getHijriOffset();
      final city = SunTimesCalculator.getCityByKey(await getSelectedCityKey());
      final method = PrayerTimesCalculator.getMethodByKey(await getPrayerMethodKey(), cityKey: city.key);
      final hanafi = await isHanafiAsr();
      final soundMode = await getPrayerSoundMode();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int fastingNotifId = 1000;
      int adhkarNotifId = 2000;
      int prayerNotifId = 3000;

      // 1. Schedule 5 Prayers + Sunrise for the next 10 days
      final Map<String, bool> prayerFlags = {
        'fajr': await isPrayerNotifEnabled('fajr'),
        'sunrise': await isPrayerNotifEnabled('sunrise'),
        'dhuhr': await isPrayerNotifEnabled('dhuhr'),
        'asr': await isPrayerNotifEnabled('asr'),
        'maghrib': await isPrayerNotifEnabled('maghrib'),
        'isha': await isPrayerNotifEnabled('isha'),
      };

      for (int i = 0; i <= 10; i++) {
        final targetDay = today.add(Duration(days: i));
        final times = PrayerTimesCalculator.calculate(
          date: targetDay,
          city: city,
          method: method,
          hanafiAsr: hanafi,
        );

        for (final entry in times.allEntries) {
          if (prayerFlags[entry.key] != true) continue;
          if (!entry.time.isAfter(now)) continue;

          final effectiveMode = entry.key == 'sunrise' && soundMode == 'azan' ? 'takbeer' : soundMode;
          final title = entry.isFardPrayer
              ? 'حان الآن موعد صلاة ${entry.nameAr}'
              : 'حان الآن وقت الشروق (${city.nameAr})';
          final body = entry.isFardPrayer
              ? 'حيّ على الصلاة، حيّ على الفلاح • ${_fmtTime12(entry.time)}'
              : 'انتهى وقت الفجر وأشرقت الشمس';

          await _scheduleOne(
            id: prayerNotifId++,
            scheduledLocal: entry.time,
            title: title,
            body: body,
            channelId: _prayerChannelForMode(effectiveMode),
            channelName: _prayerChannelName,
            channelDesc: _prayerChannelDesc,
            androidSound: _prayerSoundForMode(effectiveMode),
            payload: 'prayer:${entry.key}',
          );
        }
      }

      // 2. Schedule Morning (dynamic mins before Shuruq) & Evening (dynamic mins before Maghrib) Adhkar — HEADER ONLY
      if (morningAdhkarOn || eveningAdhkarOn) {
        for (int i = 0; i <= 20; i++) {
          final targetDay = today.add(Duration(days: i));
          final sun = SunTimesCalculator.calculate(targetDay, city.lat, city.lng);
          final morningTarget = sun.morningReminder(minutesBefore: morningOffset);
          final eveningTarget = sun.eveningReminder(minutesBefore: eveningOffset);

          if (morningAdhkarOn && morningTarget.isAfter(now)) {
            await _scheduleOne(
              id: adhkarNotifId++,
              scheduledLocal: morningTarget,
              title: 'أذكار الصباح',
              body: null,
              channelId: _adhkarChannelId,
              channelName: _adhkarChannelName,
              channelDesc: _adhkarChannelDesc,
              payload: 'misbaha:morning',
            );
          }

          if (eveningAdhkarOn && eveningTarget.isAfter(now)) {
            await _scheduleOne(
              id: adhkarNotifId++,
              scheduledLocal: eveningTarget,
              title: 'أذكار المساء',
              body: null,
              channelId: _adhkarChannelId,
              channelName: _adhkarChannelName,
              channelDesc: _adhkarChannelDesc,
              payload: 'misbaha:evening',
            );
          }
        }
      }

      // 3. Schedule Fasting Reminders (Monday, Thursday, and 13/14/15 Hijri) over next 45 days
      if (monThuOn || ayyamOn) {
        for (int i = 0; i <= 45; i++) {
          final targetDay = today.add(Duration(days: i));
          final hijri = HijriCalendar.fromGregorian(targetDay, offsetDays: offset);

          if (hijri.isProhibitedFastingDay || hijri.isRamadan) continue;

          final bool matchMonThu = monThuOn && hijri.isRecommendedMonThu;
          final bool matchBeed = ayyamOn && hijri.isRecommendedAyyamBeed;
          if (!matchMonThu && !matchBeed) continue;

          final List<String> tags = [];
          if (hijri.isMonday) tags.add('الإثنين');
          if (hijri.isThursday) tags.add('الخميس');
          if (hijri.isAyyamAlBeed) tags.add('الأيام البيض (${hijri.day} ${hijri.monthName})');
          final reasonStr = tags.join(' و');

          final eveLocal = DateTime(
            targetDay.year,
            targetDay.month,
            targetDay.day,
            evHour,
            evMinute,
          ).subtract(const Duration(days: 1));

          if (eveLocal.isAfter(now)) {
            await _scheduleOne(
              id: fastingNotifId++,
              scheduledLocal: eveLocal,
              title: 'تذكير بصيام غداً: $reasonStr',
              body: 'لا تنسَ تبييت نية الصيام والاستعداد للسحور.',
              channelId: _fastingChannelId,
              channelName: _fastingChannelName,
              channelDesc: _fastingChannelDesc,
            );
          }

          final morningLocal = DateTime(targetDay.year, targetDay.month, targetDay.day, 7, 0);
          if (morningLocal.isAfter(now)) {
            await _scheduleOne(
              id: fastingNotifId++,
              scheduledLocal: morningLocal,
              title: 'اليوم صيام سُنّة: $reasonStr',
              body: 'تقبل الله صيامك.',
              channelId: _fastingChannelId,
              channelName: _fastingChannelName,
              channelDesc: _fastingChannelDesc,
            );
          }
        }
      }

      // Refresh ongoing Salah notification after cancelAll
      await updateOngoingPrayerNotification();

      debugPrint('Scheduled ${prayerNotifId - 3000} prayer, ${adhkarNotifId - 2000} adhkar, ${fastingNotifId - 1000} fasting reminders.');
    } catch (e) {
      debugPrint('Error scheduling reminders: $e');
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required DateTime scheduledLocal,
    required String title,
    String? body,
    required String channelId,
    required String channelName,
    required String channelDesc,
    AndroidNotificationSound? androidSound,
    String? payload,
  }) async {
    final utcTarget = scheduledLocal.toUtc();
    final tzDate = tz.TZDateTime.utc(
      utcTarget.year,
      utcTarget.month,
      utcTarget.day,
      utcTarget.hour,
      utcTarget.minute,
      utcTarget.second,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: androidSound,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification #$id: $e');
    }
  }
}
