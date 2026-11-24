import 'package:flutter/foundation.dart';
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

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Holds `'morning'` or `'evening'` when a user taps an Adhkar notification.
  final ValueNotifier<String?> pendingMisbahaMode = ValueNotifier<String?>(null);

  /// Holds `'fajr'`, `'sunrise'`, `'dhuhr'`, `'asr'`, `'maghrib'`, or `'isha'` when a prayer notification is tapped.
  final ValueNotifier<String?> pendingPrayerKey = ValueNotifier<String?>(null);

  static const String _prefMonThuEnabled = 'notif_mon_thu_enabled';
  static const String _prefAyyamBeedEnabled = 'notif_ayyam_beed_enabled';
  static const String _prefMorningAdhkarEnabled = 'notif_morning_adhkar_enabled';
  static const String _prefEveningAdhkarEnabled = 'notif_evening_adhkar_enabled';
  static const String _prefEveningHour = 'notif_evening_hour';
  static const String _prefEveningMinute = 'notif_evening_minute';
  static const String _prefHijriOffset = 'hijri_date_offset';
  static const String _prefCityKey = 'sun_times_city_key';
  static const String _prefPrayerSoundMode = 'prayer_sound_mode'; // 'azan', 'takbeer', 'default'
  static const String _prefPrayerMethodKey = 'prayer_method_key';
  static const String _prefHanafiAsr = 'prayer_hanafi_asr';

  static const String _fastingChannelId = 'adhkar_fasting_reminders';
  static const String _fastingChannelName = 'تذكير صيام التطوع والأيام البيض';
  static const String _fastingChannelDesc = 'تنبيهات تذكيرية لصيام الإثنين والخميس والأيام البيض (١٣، ١٤، ١٥ هجري)';

  static const String _adhkarChannelId = 'adhkar_morning_evening_reminders';
  static const String _adhkarChannelName = 'تذكير أذكار الصباح والمساء';
  static const String _adhkarChannelDesc = 'تنبيهات تلقائية قبل الشروق بنصف ساعة وقبل المغرب بنصف ساعة';

  // Separate channel IDs per sound so Android OS never caches the wrong sound
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
        _handlePayload(response.payload);
      },
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _handlePayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Launch details check notice: $e');
    }

    _initialized = true;
    await scheduleAllReminders();
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (payload == 'misbaha:morning') {
      pendingMisbahaMode.value = 'morning';
    } else if (payload == 'misbaha:evening') {
      pendingMisbahaMode.value = 'evening';
    } else if (payload.startsWith('prayer:')) {
      pendingPrayerKey.value = payload.substring('prayer:'.length);
    }
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
    int? eveningHour,
    int? eveningMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (monThuEnabled != null) await prefs.setBool(_prefMonThuEnabled, monThuEnabled);
    if (ayyamBeedEnabled != null) await prefs.setBool(_prefAyyamBeedEnabled, ayyamBeedEnabled);
    if (morningAdhkarEnabled != null) await prefs.setBool(_prefMorningAdhkarEnabled, morningAdhkarEnabled);
    if (eveningAdhkarEnabled != null) await prefs.setBool(_prefEveningAdhkarEnabled, eveningAdhkarEnabled);
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

  /// Schedules:
  /// 1) 5 Daily Prayers + Sunrise notifications (with Azan, Takbeer, or Default sound)
  /// 2) Morning Adhkar (30m before Shuruq) & Evening Adhkar (30m before Maghrib)
  /// 3) Fasting reminders (Monday, Thursday, and 13/14/15 Hijri)
  Future<void> scheduleAllReminders() async {
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();

      final monThuOn = await isMonThuEnabled();
      final ayyamOn = await isAyyamBeedEnabled();
      final morningAdhkarOn = await isMorningAdhkarEnabled();
      final eveningAdhkarOn = await isEveningAdhkarEnabled();

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

          // Sunrise uses gentle Takbeer/Default (no full Adhan for sunrise, since sunrise is not a fard salah)
          final effectiveMode = entry.key == 'sunrise' && soundMode == 'azan' ? 'takbeer' : soundMode;
          final title = entry.isFardPrayer
              ? '🕌 حان الآن موعد صلاة ${entry.nameAr}'
              : '☀️ حان الآن وقت الشروق (${city.nameAr})';
          final body = entry.isFardPrayer
              ? 'حيّ على الصلاة، حيّ على الفلاح • ${city.nameAr} (${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')})'
              : 'انتهى وقت الفجر وأشرقت الشمس • لا تنسَ صلاة الضحى بعد قليل';

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

      // 2. Schedule Morning (30m before Shuruq) & Evening (30m before Maghrib) Adhkar for next 20 days
      if (morningAdhkarOn || eveningAdhkarOn) {
        for (int i = 0; i <= 20; i++) {
          final targetDay = today.add(Duration(days: i));
          final sun = SunTimesCalculator.calculate(targetDay, city.lat, city.lng);

          if (morningAdhkarOn && sun.morningAdhkarReminder.isAfter(now)) {
            await _scheduleOne(
              id: adhkarNotifId++,
              scheduledLocal: sun.morningAdhkarReminder,
              title: '☀️ أذكار الصباح (قبل الشروق بنصف ساعة)',
              body: 'اضغط لفتح المسبحة مع أذكار الصباح • تُسجّل تلقائياً (+١٥ نقطة) في الورد اليومي',
              channelId: _adhkarChannelId,
              channelName: _adhkarChannelName,
              channelDesc: _adhkarChannelDesc,
              payload: 'misbaha:morning',
            );
          }

          if (eveningAdhkarOn && sun.eveningAdhkarReminder.isAfter(now)) {
            await _scheduleOne(
              id: adhkarNotifId++,
              scheduledLocal: sun.eveningAdhkarReminder,
              title: '🌙 أذكار المساء (قبل المغرب بنصف ساعة)',
              body: 'اضغط لفتح المسبحة مع أذكار المساء • تُسجّل تلقائياً (+١٥ نقطة) في الورد اليومي',
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
              title: '🌙 تذكير بصيام غداً: $reasonStr',
              body: '«تُعرض الأعمال يوم الإثنين والخميس» • لا تنسَ تبييت نية الصيام والاستعداد للسحور.',
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
              title: '☀️ اليوم صيام سُنّة: $reasonStr',
              body: 'تقبل الله صيامك! يمكنك تسجيل صيام اليوم في الورد اليومي لكسب النقاط الإضافية.',
              channelId: _fastingChannelId,
              channelName: _fastingChannelName,
              channelDesc: _fastingChannelDesc,
            );
          }
        }
      }

      debugPrint('Scheduled ${prayerNotifId - 3000} prayer, ${adhkarNotifId - 2000} adhkar, ${fastingNotifId - 1000} fasting reminders.');
    } catch (e) {
      debugPrint('Error scheduling reminders: $e');
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required DateTime scheduledLocal,
    required String title,
    required String body,
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

  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    await requestPermissions();
    final offset = await getHijriOffset();
    final hijri = HijriCalendar.fromGregorian(DateTime.now(), offsetDays: offset);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _fastingChannelId,
        _fastingChannelName,
        channelDescription: _fastingChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      9999,
      '🌙 تذكير الصيام والتقويم الهجري مفعل!',
      'التاريخ اليوم: ${hijri.formattedArabic}. سيتم تنبيهك تلقائياً لصيام الإثنين والخميس والأيام البيض.',
      details,
    );
  }

  Future<void> showTestAdhkarNotification(String mode) async {
    if (!_initialized) await init();
    await requestPermissions();
    final isMorning = mode == 'morning';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _adhkarChannelId,
        _adhkarChannelName,
        channelDescription: _adhkarChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      isMorning ? 9991 : 9992,
      isMorning ? '☀️ حان موعد أذكار الصباح' : '🌙 حان موعد أذكار المساء',
      isMorning
          ? 'اضغط هنا لفتح المسبحة مباشرة على أذكار الصباح (+١٥ نقطة عند الإتمام)'
          : 'اضغط هنا لفتح المسبحة مباشرة على أذكار المساء (+١٥ نقطة عند الإتمام)',
      details,
      payload: 'misbaha:$mode',
    );
  }

  Future<void> showTestPrayerNotification() async {
    if (!_initialized) await init();
    await requestPermissions();
    final mode = await getPrayerSoundMode();
    final city = SunTimesCalculator.getCityByKey(await getSelectedCityKey());

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _prayerChannelForMode(mode),
        _prayerChannelName,
        channelDescription: _prayerChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: _prayerSoundForMode(mode),
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      9993,
      '🕌 تجربة إشعار الأذان (${city.nameAr})',
      mode == 'azan'
          ? 'تسمع الآن صوت أذان الحرم المكي عند دخول وقت الصلاة'
          : (mode == 'takbeer' ? 'تسمع الآن تكبيرة الأذان المختصرة' : 'صوت تنبيهات النظام الافتراضي'),
      details,
      payload: 'prayer:dhuhr',
    );
  }
}
