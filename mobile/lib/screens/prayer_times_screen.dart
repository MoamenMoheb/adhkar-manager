import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/hijri_calendar.dart';
import '../core/utils/sun_times.dart';
import '../core/utils/prayer_times.dart';
import '../services/azan_audio_service.dart';
import '../services/notification_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final NotificationService _notif = NotificationService.instance;
  final AzanAudioService _audio = AzanAudioService.instance;

  Timer? _ticker;
  DateTime _now = DateTime.now();

  String _cityKey = SunTimesCalculator.defaultCityForLocalTimezone().key;
  String? _methodKey;
  bool _hanafiAsr = false;
  String _soundMode = 'azan'; // 'azan', 'takbeer', 'default'
  int _hijriOffset = 0;

  final Map<String, bool> _prayerFlags = {
    'fajr': true,
    'sunrise': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final cityKey = await _notif.getSelectedCityKey();
    final methodKey = await _notif.getPrayerMethodKey();
    final hanafi = await _notif.isHanafiAsr();
    final soundMode = await _notif.getPrayerSoundMode();
    final offset = await _notif.getHijriOffset();
    for (final k in _prayerFlags.keys.toList()) {
      _prayerFlags[k] = await _notif.isPrayerNotifEnabled(k);
    }
    if (!mounted) return;
    setState(() {
      _cityKey = cityKey;
      _methodKey = methodKey;
      _hanafiAsr = hanafi;
      _soundMode = soundMode;
      _hijriOffset = offset;
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'م' : 'ص';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  String _formatCountdown(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 86400 * 2);
    final hrs = (totalSec ~/ 3600).toString().padLeft(2, '0');
    final mins = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
  }

  IconData _iconForPrayer(String key) {
    switch (key) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'dhuhr':
        return Icons.light_mode;
      case 'asr':
        return Icons.wb_sunny;
      case 'maghrib':
        return Icons.nights_stay_outlined;
      case 'isha':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = SunTimesCalculator.getCityByKey(_cityKey);
    final method = PrayerTimesCalculator.getMethodByKey(_methodKey, cityKey: city.key);
    final times = PrayerTimesCalculator.calculate(
      date: _now,
      city: city,
      method: method,
      hanafiAsr: _hanafiAsr,
    );
    final nextPrayer = PrayerTimesCalculator.getNextPrayer(
      now: _now,
      city: city,
      method: method,
      hanafiAsr: _hanafiAsr,
    );
    final remaining = nextPrayer.time.difference(_now);
    final hijri = HijriCalendar.fromGregorian(_now, offsetDays: _hijriOffset);

    return Scaffold(
      appBar: AppBar(
        title: Text('مواقيت الصلاة والأذان', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Live Countdown Hero Card + Azan Audio Control
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppConstants.primary, AppConstants.primaryContainer],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppConstants.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(city.nameAr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Text(hijri.shortArabic, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        nextPrayer.isFardPrayer ? 'الصلاة القادمة: ${nextPrayer.nameAr}' : 'الموعد القادم: ${nextPrayer.nameAr}',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCountdown(remaining),
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'موعد الأذان: ${_formatTime(nextPrayer.time)}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Live Play / Stop Azan Audio Button
                ValueListenableBuilder<bool>(
                  valueListenable: _audio.isPlaying,
                  builder: (context, playing, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: playing ? Colors.amber : Colors.white.withOpacity(0.18),
                              foregroundColor: playing ? Colors.black87 : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: Icon(playing ? Icons.stop_circle : Icons.volume_up),
                            label: Text(
                              playing ? 'إيقاف صوت الأذان' : 'تشغيل أذان الحرم المكي 🕌',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => _audio.playAzan(shortTakbeer: false),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. All 5 Prayers + Sunrise Cards
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: times.allEntries.map((entry) {
                  final isNext = entry.key == nextPrayer.key && entry.time.day == nextPrayer.time.day;
                  final isNotifOn = _prayerFlags[entry.key] ?? true;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isNext ? AppConstants.primary.withOpacity(0.09) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isNext ? Border.all(color: AppConstants.primary.withOpacity(0.35)) : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isNext
                              ? AppConstants.primary
                              : (entry.isFardPrayer ? AppConstants.secondary.withOpacity(0.12) : Colors.amber.withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconForPrayer(entry.key),
                          size: 20,
                          color: isNext ? Colors.white : (entry.isFardPrayer ? AppConstants.secondary : AppConstants.tertiary),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            entry.nameAr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isNext ? AppConstants.primary : null,
                            ),
                          ),
                          if (isNext) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppConstants.primary, borderRadius: BorderRadius.circular(8)),
                              child: const Text('التالي', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: entry.key == 'sunrise'
                          ? const Text('تذكير انتهاء وقت الفجر (صلاة الضحى)', style: TextStyle(fontSize: 11))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(entry.time),
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isNext ? AppConstants.primary : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(
                              isNotifOn ? Icons.notifications_active : Icons.notifications_off_outlined,
                              color: isNotifOn ? AppConstants.tertiary : Colors.grey,
                              size: 20,
                            ),
                            tooltip: isNotifOn ? 'إيقاف التنبيه' : 'تفعيل التنبيه',
                            onPressed: () async {
                              await _notif.requestPermissions();
                              await _notif.setPrayerNotifEnabled(entry.key, !isNotifOn);
                              setState(() => _prayerFlags[entry.key] = !isNotifOn);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Azan Sound & Calculation Settings Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إعدادات صوت الأذان وطريقة الحساب', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 22),

                  const Text('صوت تنبيه دخول وقت الصلاة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🕌 صوت الأذان الكامل (أذان الحرم المكي)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: 'azan',
                    groupValue: _soundMode,
                    activeColor: AppConstants.primary,
                    onChanged: (val) async {
                      if (val != null) {
                        await _notif.setPrayerSoundMode(val);
                        setState(() => _soundMode = val);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🔔 تكبيرة الأذان المختصرة (١٠ ثوانٍ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: 'takbeer',
                    groupValue: _soundMode,
                    activeColor: AppConstants.primary,
                    onChanged: (val) async {
                      if (val != null) {
                        await _notif.setPrayerSoundMode(val);
                        setState(() => _soundMode = val);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🔊 نغمة الإشعارات الافتراضية للهاتف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: 'default',
                    groupValue: _soundMode,
                    activeColor: AppConstants.primary,
                    onChanged: (val) async {
                      if (val != null) {
                        await _notif.setPrayerSoundMode(val);
                        setState(() => _soundMode = val);
                      }
                    },
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('معاينة الصوت', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            if (_soundMode == 'takbeer') {
                              _audio.playAzan(shortTakbeer: true);
                            } else {
                              _audio.playAzan(shortTakbeer: false);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary, foregroundColor: Colors.white),
                          icon: const Icon(Icons.notifications_active, size: 18),
                          label: const Text('تجربة إشعار الأذان', style: TextStyle(fontSize: 12)),
                          onPressed: () => _notif.showTestPrayerNotification(),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  DropdownButtonFormField<String>(
                    value: city.key,
                    decoration: InputDecoration(
                      labelText: 'المدينة',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: SunTimesCalculator.cities
                        .map((c) => DropdownMenuItem(value: c.key, child: Text(c.nameAr, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await _notif.setSelectedCityKey(val);
                        setState(() => _cityKey = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method.key,
                    decoration: InputDecoration(
                      labelText: 'طريقة حساب المواقيت',
                      prefixIcon: const Icon(Icons.calculate_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: PrayerTimesCalculator.methods
                        .map((m) => DropdownMenuItem(value: m.key, child: Text(m.nameAr, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await _notif.setPrayerMethodKey(val);
                        setState(() => _methodKey = val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('المذهب الحنفي لصلاة العصر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('افتراضي: مذهب الجمهور (الشافعي والمالكي والحنبلي)', style: TextStyle(fontSize: 11)),
                    value: _hanafiAsr,
                    activeColor: AppConstants.primary,
                    onChanged: (val) async {
                      await _notif.setHanafiAsr(val);
                      setState(() => _hanafiAsr = val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
