import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/app_locale.dart';
import '../core/utils/sun_times.dart';
import '../services/azan_audio_service.dart';
import '../services/notification_service.dart';
import 'azan_settings_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notif = NotificationService.instance;

  bool _loading = true;
  bool _monThuEnabled = true;
  bool _ayyamBeedEnabled = true;
  bool _morningAdhkarEnabled = true;
  bool _eveningAdhkarEnabled = true;
  int _morningOffsetMin = 30;
  int _eveningOffsetMin = 30;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 30);
  int _hijriOffset = 0;
  String _cityKey = SunTimesCalculator.defaultCityForLocalTimezone().key;
  String _soundMode = 'azan';

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
    _loadAll();
  }

  Future<void> _loadAll() async {
    final monThu = await _notif.isMonThuEnabled();
    final ayyam = await _notif.isAyyamBeedEnabled();
    final morningAdhkar = await _notif.isMorningAdhkarEnabled();
    final eveningAdhkar = await _notif.isEveningAdhkarEnabled();
    final morningOff = await _notif.getMorningAdhkarOffsetMinutes();
    final eveningOff = await _notif.getEveningAdhkarOffsetMinutes();
    final evTime = await _notif.getEveningReminderTime();
    final hijriOff = await _notif.getHijriOffset();
    final cityKey = await _notif.getSelectedCityKey();
    final sound = await _notif.getPrayerSoundMode();
    for (final k in _prayerFlags.keys.toList()) {
      _prayerFlags[k] = await _notif.isPrayerNotifEnabled(k);
    }

    if (!mounted) return;
    setState(() {
      _monThuEnabled = monThu;
      _ayyamBeedEnabled = ayyam;
      _morningAdhkarEnabled = morningAdhkar;
      _eveningAdhkarEnabled = eveningAdhkar;
      _morningOffsetMin = morningOff;
      _eveningOffsetMin = eveningOff;
      _eveningTime = TimeOfDay(hour: evTime[0], minute: evTime[1]);
      _hijriOffset = hijriOff;
      _cityKey = cityKey;
      _soundMode = sound;
      _loading = false;
    });
  }

  String _prayerTitle(String key, bool isAr) {
    switch (key) {
      case 'fajr':
        return isAr ? 'صلاة الفجر' : 'Fajr';
      case 'sunrise':
        return isAr ? 'الشروق' : 'Sunrise';
      case 'dhuhr':
        return isAr ? 'صلاة الظهر' : 'Dhuhr';
      case 'asr':
        return isAr ? 'صلاة العصر' : 'Asr';
      case 'maghrib':
        return isAr ? 'صلاة المغرب' : 'Maghrib';
      case 'isha':
        return isAr ? 'صلاة العشاء' : 'Isha';
      default:
        return key;
    }
  }

  Future<void> _updateAdhkarOffset({required bool isMorning, required int minutes}) async {
    final clamped = minutes.clamp(1, 180);
    await _notif.requestPermissions();
    if (isMorning) {
      await _notif.updateSettings(morningAdhkarOffsetMin: clamped);
      if (mounted) setState(() => _morningOffsetMin = clamped);
    } else {
      await _notif.updateSettings(eveningAdhkarOffsetMin: clamped);
      if (mounted) setState(() => _eveningOffsetMin = clamped);
    }
  }

  Future<void> _showCustomOffsetDialog({required bool isMorning}) async {
    final isAr = AppLocale.instance.isAr;
    final controller = TextEditingController(
      text: (isMorning ? _morningOffsetMin : _eveningOffsetMin).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isMorning
              ? (isAr ? 'توقيت أذكار الصباح' : 'Morning Adhkar Timing')
              : (isAr ? 'توقيت أذكار المساء' : 'Evening Adhkar Timing'),
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isMorning
                ? (isAr ? 'عدد الدقائق قبل الشروق' : 'Minutes before Sunrise')
                : (isAr ? 'عدد الدقائق قبل المغرب' : 'Minutes before Maghrib'),
            suffixText: isAr ? 'دقيقة' : 'min',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1 && val <= 180) {
                Navigator.pop(ctx, val);
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _updateAdhkarOffset(isMorning: isMorning, minutes: result);
    }
  }

  Widget _buildOffsetSelector({
    required bool isMorning,
    required int currentMinutes,
    required Color secondaryTxt,
  }) {
    final isAr = AppLocale.instance.isAr;
    final isDark = AppConstants.isDark(context);
    final activeBg = isDark ? const Color(0xFFF3F4F6) : AppConstants.primary;
    final activeFg = isDark ? const Color(0xFF0E1117) : Colors.white;
    const presets = [15, 20, 30, 60];
    final isCustom = !presets.contains(currentMinutes);

    Widget buildPill(String label, bool active, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? activeBg : AppConstants.activeSurface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? activeBg : AppConstants.borderColor(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? activeFg : secondaryTxt,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          buildPill(isAr ? '١٥ د' : '15m', currentMinutes == 15, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 15)),
          buildPill(isAr ? '٢٠ د' : '20m', currentMinutes == 20, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 20)),
          buildPill(isAr ? '٣٠ د' : '30m', currentMinutes == 30, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 30)),
          buildPill(isAr ? '٦٠ د' : '60m', currentMinutes == 60, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 60)),
          buildPill(
            isCustom ? '$currentMinutes ${isAr ? "د" : "m"}' : (isAr ? 'تخصيص' : 'Custom'),
            isCustom,
            () => _showCustomOffsetDialog(isMorning: isMorning),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocale.instance.isAr;
    final tr = AppLocale.instance.tr;
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final city = SunTimesCalculator.getCityByKey(_cityKey);
    final sun = SunTimesCalculator.calculate(DateTime.now(), city.lat, city.lng);
    final morningRem = sun.morningReminder(minutesBefore: _morningOffsetMin);
    final eveningRem = sun.eveningReminder(minutesBefore: _eveningOffsetMin);
    String fmtTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('إعدادات الإشعارات', 'Notification Settings'),
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Sticky Salah Notification & Fullscreen Azan
                Card(
                  elevation: 0,
                  color: AppConstants.cardSurface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('إشعارات الصلاة والأذان', 'Prayer & Azan Notifications'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryTxt,
                          ),
                        ),
                        const Divider(height: 20),
                        ValueListenableBuilder<bool>(
                          valueListenable: _notif.fixedPrayerNotifNotifier,
                          builder: (context, isFixedEnabled, _) {
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(Icons.push_pin_outlined, color: primaryTxt),
                              title: Text(
                                tr('إشعار الصلاة القادمة الدائم', 'Sticky Next Prayer Notification'),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt),
                              ),
                              subtitle: Text(
                                tr(
                                  'يثبت العد التنازلي للصلاة القادمة في شريط الإشعارات',
                                  'Keeps the upcoming prayer countdown pinned in status bar',
                                ),
                                style: TextStyle(fontSize: 11, color: secondaryTxt),
                              ),
                              value: isFixedEnabled,
                              onChanged: (val) async {
                                await _notif.requestPermissions();
                                await _notif.setFixedPrayerNotifEnabled(val);
                              },
                            );
                          },
                        ),
                        const Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.layers_outlined, color: AppConstants.secondary),
                          title: Text(
                            tr('شاشة الأذان الكاملة وأصوات المؤذنين', 'Azan Wall Screen & Muezzin Voices'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt),
                          ),
                          subtitle: Text(
                            '${tr("الصوت الحالي:", "Current:")} ${AzanAudioService.findTrack(_soundMode).titleAr}',
                            style: TextStyle(fontSize: 11, color: secondaryTxt),
                          ),
                          trailing: Icon(Icons.chevron_right, color: secondaryTxt),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AzanSettingsScreen()),
                            );
                            await _loadAll();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Per-Prayer Notification Toggles
                Card(
                  elevation: 0,
                  color: AppConstants.cardSurface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('تنبيهات كل صلاة', 'Individual Prayer Alerts'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryTxt,
                          ),
                        ),
                        const Divider(height: 18),
                        ..._prayerFlags.entries.map((entry) {
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              _prayerTitle(entry.key, isAr),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt),
                            ),
                            value: entry.value,
                            onChanged: (val) async {
                              await _notif.requestPermissions();
                              await _notif.setPrayerNotifEnabled(entry.key, val);
                              if (mounted) setState(() => _prayerFlags[entry.key] = val);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Morning & Evening Adhkar Reminders
                Card(
                  elevation: 0,
                  color: AppConstants.cardSurface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('تنبيهات أذكار الصباح والمساء', 'Morning & Evening Adhkar Alerts'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryTxt,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: city.key,
                          decoration: InputDecoration(
                            labelText: tr('المدينة', 'City'),
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: SunTimesCalculator.cities
                              .map((c) => DropdownMenuItem(value: c.key, child: Text(c.nameAr, style: TextStyle(fontSize: 13, color: primaryTxt))))
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              await _notif.setSelectedCityKey(val);
                              if (mounted) setState(() => _cityKey = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('أذكار الصباح', 'Morning Adhkar'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                          subtitle: Text(
                            '${tr("قبل الشروق بـ", "Before sunrise by")} $_morningOffsetMin ${tr("د", "min")} (${fmtTime(morningRem)})',
                            style: TextStyle(fontSize: 11, color: secondaryTxt),
                          ),
                          value: _morningAdhkarEnabled,
                          onChanged: (val) async {
                            await _notif.requestPermissions();
                            await _notif.updateSettings(morningAdhkarEnabled: val);
                            if (mounted) setState(() => _morningAdhkarEnabled = val);
                          },
                        ),
                        _buildOffsetSelector(isMorning: true, currentMinutes: _morningOffsetMin, secondaryTxt: secondaryTxt),
                        const Divider(height: 18),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('أذكار المساء', 'Evening Adhkar'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                          subtitle: Text(
                            '${tr("قبل المغرب بـ", "Before sunset by")} $_eveningOffsetMin ${tr("د", "min")} (${fmtTime(eveningRem)})',
                            style: TextStyle(fontSize: 11, color: secondaryTxt),
                          ),
                          value: _eveningAdhkarEnabled,
                          onChanged: (val) async {
                            await _notif.requestPermissions();
                            await _notif.updateSettings(eveningAdhkarEnabled: val);
                            if (mounted) setState(() => _eveningAdhkarEnabled = val);
                          },
                        ),
                        _buildOffsetSelector(isMorning: false, currentMinutes: _eveningOffsetMin, secondaryTxt: secondaryTxt),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Voluntary Fasting Reminders & Hijri Offset
                Card(
                  elevation: 0,
                  color: AppConstants.cardSurface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('تنبيهات الصيام والتقويم الهجري', 'Fasting Alerts & Hijri Offset'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryTxt,
                          ),
                        ),
                        const Divider(height: 18),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('تذكير صيام الإثنين والخميس', 'Monday & Thursday Fasting'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                          value: _monThuEnabled,
                          onChanged: (val) async {
                            await _notif.requestPermissions();
                            await _notif.updateSettings(monThuEnabled: val);
                            if (mounted) setState(() => _monThuEnabled = val);
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('تذكير الأيام البيض (١٣، ١٤، ١٥)', 'White Days (13, 14, 15 Hijri)'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                          value: _ayyamBeedEnabled,
                          onChanged: (val) async {
                            await _notif.requestPermissions();
                            await _notif.updateSettings(ayyamBeedEnabled: val);
                            if (mounted) setState(() => _ayyamBeedEnabled = val);
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('وقت التذكير المسائي للصيام', 'Evening Fasting Reminder Time'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTxt)),
                          trailing: Chip(label: Text(_eveningTime.format(context))),
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: _eveningTime);
                            if (picked != null) {
                              await _notif.updateSettings(eveningHour: picked.hour, eveningMinute: picked.minute);
                              if (mounted) setState(() => _eveningTime = picked);
                            }
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('تعديل التاريخ الهجري:', 'Hijri Date Offset:'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTxt)),
                            DropdownButton<int>(
                              value: _hijriOffset,
                              items: [-2, -1, 0, 1, 2]
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d == 0 ? tr('تلقائي (٠)', 'Auto (0)') : '${d > 0 ? "+$d" : d}')))
                                  .toList(),
                              onChanged: (val) async {
                                if (val != null) {
                                  await _notif.setHijriOffset(val);
                                  if (mounted) setState(() => _hijriOffset = val);
                                }
                              },
                            ),
                          ],
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
