import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/hijri_calendar.dart';
import '../core/utils/sun_times.dart';
import '../services/notification_service.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  final NotificationService _notifService = NotificationService.instance;

  late int _viewYear;
  late int _viewMonth;
  int _hijriOffset = 0;
  HijriDate? _selectedDay;

  bool _monThuEnabled = true;
  bool _ayyamBeedEnabled = true;
  bool _morningAdhkarEnabled = true;
  bool _eveningAdhkarEnabled = true;
  String _cityKey = SunTimesCalculator.defaultCityForLocalTimezone().key;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 30);
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    final todayHijri = HijriCalendar.fromGregorian(DateTime.now());
    _viewYear = todayHijri.year;
    _viewMonth = todayHijri.month;
    _selectedDay = todayHijri;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final offset = await _notifService.getHijriOffset();
    final monThu = await _notifService.isMonThuEnabled();
    final ayyam = await _notifService.isAyyamBeedEnabled();
    final morningAdhkar = await _notifService.isMorningAdhkarEnabled();
    final eveningAdhkar = await _notifService.isEveningAdhkarEnabled();
    final cityKey = await _notifService.getSelectedCityKey();
    final evTime = await _notifService.getEveningReminderTime();

    final todayHijri = HijriCalendar.fromGregorian(DateTime.now(), offsetDays: offset);
    if (!mounted) return;
    setState(() {
      _hijriOffset = offset;
      _monThuEnabled = monThu;
      _ayyamBeedEnabled = ayyam;
      _morningAdhkarEnabled = morningAdhkar;
      _eveningAdhkarEnabled = eveningAdhkar;
      _cityKey = cityKey;
      _eveningTime = TimeOfDay(hour: evTime[0], minute: evTime[1]);
      _viewYear = todayHijri.year;
      _viewMonth = todayHijri.month;
      _selectedDay = todayHijri;
      _loadingPrefs = false;
    });
  }

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
  }

  void _goToToday() {
    final todayHijri = HijriCalendar.fromGregorian(DateTime.now(), offsetDays: _hijriOffset);
    setState(() {
      _viewYear = todayHijri.year;
      _viewMonth = todayHijri.month;
      _selectedDay = todayHijri;
    });
  }

  Future<void> _changeOffset(int delta) async {
    final newOffset = (_hijriOffset + delta).clamp(-2, 2);
    if (newOffset == _hijriOffset) return;
    await _notifService.setHijriOffset(newOffset);
    final todayHijri = HijriCalendar.fromGregorian(DateTime.now(), offsetDays: newOffset);
    setState(() {
      _hijriOffset = newOffset;
      _viewYear = todayHijri.year;
      _viewMonth = todayHijri.month;
      _selectedDay = todayHijri;
    });
  }

  bool _isSameGregorian(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _gregorianShort(DateTime dt) {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayHijri = HijriCalendar.fromGregorian(today, offsetDays: _hijriOffset);
    final tomorrowHijri = HijriCalendar.fromGregorian(today.add(const Duration(days: 1)), offsetDays: _hijriOffset);
    final monthDays = HijriCalendar.getMonthDays(_viewYear, _viewMonth, offsetDays: _hijriOffset);

    // Calendar grid starts Saturday (Dart weekday: Sat=6, Sun=7, Mon=1..Fri=5)
    // Offset mapping so Saturday=0, Sunday=1, Monday=2, Tuesday=3, Wednesday=4, Thursday=5, Friday=6
    int weekdayToGridIndex(int weekday) {
      if (weekday == DateTime.saturday) return 0;
      if (weekday == DateTime.sunday) return 1;
      return weekday + 1; // Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
    }

    final firstLeadingEmpty = weekdayToGridIndex(monthDays.first.gregorian.weekday);

    return Scaffold(
      appBar: AppBar(
        title: Text('التقويم الهجري وصيام السنة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Today Hijri Banner
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
                BoxShadow(color: AppConstants.primary.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6)),
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
                        const Icon(Icons.nightlight_round, color: Colors.amber, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'التاريخ الهجري اليوم',
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    // Moon sighting offset control
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _changeOffset(-1),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.remove, color: Colors.white, size: 15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              _hijriOffset == 0 ? 'أم القرى' : '${_hijriOffset > 0 ? "+" : ""}$_hijriOffset يوم',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          InkWell(
                            onTap: () => _changeOffset(1),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.add, color: Colors.white, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  todayHijri.formattedArabic,
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'الموافق ${_gregorianShort(today)} ${today.year} م',
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13),
                ),
                if (todayHijri.isFastingDay) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'اليوم: ${todayHijri.fastingReasonLabel} — تمت إضافته لنقاط الورد اليومي!',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (tomorrowHijri.isFastingDay) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.amberAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تذكير: غداً ${tomorrowHijri.fastingReasonLabel} • استعد لتبييت النية!',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Interactive Hijri Month Calendar Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _prevMonth,
                        tooltip: 'الشهر السابق',
                      ),
                      Text(
                        '${HijriDate.monthNames[_viewMonth - 1]} $_viewYear هـ',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                        tooltip: 'الشهر التالي',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Weekday Headers
                  Row(
                    children: ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة']
                        .map((label) => Expanded(
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: (label == 'إثنين' || label == 'خميس') ? AppConstants.secondary : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Days Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: firstLeadingEmpty + monthDays.length,
                    itemBuilder: (context, index) {
                      if (index < firstLeadingEmpty) return const SizedBox.shrink();
                      final dayObj = monthDays[index - firstLeadingEmpty];
                      final isToday = _isSameGregorian(dayObj.gregorian, today);
                      final isSelected = _selectedDay != null && _isSameGregorian(dayObj.gregorian, _selectedDay!.gregorian);
                      final isBeed = dayObj.isRecommendedAyyamBeed;
                      final isMonThu = dayObj.isRecommendedMonThu;
                      final isProhibited = dayObj.isProhibitedFastingDay;

                      Color? bgColor;
                      Color borderColor = Colors.transparent;
                      if (isToday) {
                        bgColor = AppConstants.primary;
                      } else if (isBeed) {
                        bgColor = AppConstants.tertiary.withOpacity(0.16);
                        borderColor = AppConstants.tertiary;
                      } else if (isMonThu) {
                        bgColor = AppConstants.secondary.withOpacity(0.12);
                        borderColor = AppConstants.secondary.withOpacity(0.5);
                      } else if (isProhibited) {
                        bgColor = Colors.red.withOpacity(0.08);
                      }

                      if (isSelected && !isToday) {
                        borderColor = AppConstants.primary;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = dayObj),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor ?? Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppConstants.primary : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${dayObj.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isToday
                                      ? Colors.white
                                      : (isBeed ? const Color(0xFF925E00) : null),
                                ),
                              ),
                              Text(
                                '${dayObj.gregorian.day}/${dayObj.gregorian.month}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isToday ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                              if (isBeed || isMonThu)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    isBeed ? Icons.brightness_3 : Icons.circle,
                                    size: isBeed ? 9 : 6,
                                    color: isToday
                                        ? Colors.amber
                                        : (isBeed ? AppConstants.tertiary : AppConstants.secondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _legendChip(AppConstants.primary, 'اليوم'),
                      _legendChip(AppConstants.tertiary, 'الأيام البيض (١٣-١٤-١٥)'),
                      _legendChip(AppConstants.secondary, 'الإثنين والخميس'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Selected Day Info Card
          if (_selectedDay != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: AppConstants.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppConstants.primary.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDay!.formattedArabic,
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الموافق ${_gregorianShort(_selectedDay!.gregorian)} ${_selectedDay!.gregorian.year} م',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (_selectedDay!.occasionName != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.star, color: Colors.amber, size: 16),
                        label: Text(_selectedDay!.occasionName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.amber.withOpacity(0.15),
                      ),
                    ],
                    if (_selectedDay!.isFastingDay) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.mosque, color: AppConstants.secondary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'يوم صيام سُنّة: ${_selectedDay!.fastingReasonLabel}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.secondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 3. Notification Reminder Settings Card
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.tertiary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active, color: AppConstants.tertiary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تنبيهات وتذكير الصيام', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text('إشعارات تلقائية قبل الصيام لتبييت النية وفي الصباح', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_loadingPrefs)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('صيام الإثنين والخميس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('تذكير مساء الأحد والأربعاء وصباح الإثنين والخميس (+٢٥ نقطة)', style: TextStyle(fontSize: 11)),
                      value: _monThuEnabled,
                      activeColor: AppConstants.primary,
                      onChanged: (val) async {
                        await _notifService.requestPermissions();
                        await _notifService.updateSettings(monThuEnabled: val);
                        setState(() => _monThuEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('صيام الأيام البيض (١٣، ١٤، ١٥ هـ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('تذكير تلقائي كل شهر هجري للأيام البيض (+٣٠ نقطة)', style: TextStyle(fontSize: 11)),
                      value: _ayyamBeedEnabled,
                      activeColor: AppConstants.tertiary,
                      onChanged: (val) async {
                        await _notifService.requestPermissions();
                        await _notifService.updateSettings(ayyamBeedEnabled: val);
                        setState(() => _ayyamBeedEnabled = val);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: AppConstants.primary),
                      title: const Text('توقيت تذكير المساء (ليلة الصيام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _eveningTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primary),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _eveningTime);
                        if (picked != null) {
                          await _notifService.updateSettings(eveningHour: picked.hour, eveningMinute: picked.minute);
                          setState(() => _eveningTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.notifications_none),
                        label: const Text('تجربة إرسال إشعار التذكير الآن'),
                        onPressed: () async {
                          await _notifService.showTestNotification();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إرسال إشعار تجريبي وتحديث جدول التذكيرات! 🔔')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Morning & Evening Adhkar (Shuruq & Maghrib - 30 mins) Card
          Builder(
            builder: (context) {
              final city = SunTimesCalculator.getCityByKey(_cityKey);
              final sun = SunTimesCalculator.calculate(today, city.lat, city.lng);
              String fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

              return Card(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.wb_twilight, color: AppConstants.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('تنبيهات أذكار الصباح والمساء', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Text('قبل الشروق بـ ٣٠ دقيقة وقبل المغرب بـ ٣٠ دقيقة (تفتح المسبحة مباشرة)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      DropdownButtonFormField<String>(
                        value: city.key,
                        decoration: InputDecoration(
                          labelText: 'المدينة لحساب الشروق والمغرب',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: SunTimesCalculator.cities
                            .map((c) => DropdownMenuItem(value: c.key, child: Text(c.nameAr, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            await _notifService.setSelectedCityKey(val);
                            setState(() => _cityKey = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('☀️ الشروق اليوم: ${fmtTime(sun.sunrise)}', style: const TextStyle(fontSize: 12)),
                                Text('التنبيه: ${fmtTime(sun.morningAdhkarReminder)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.tertiary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🌙 المغرب اليوم: ${fmtTime(sun.sunset)}', style: const TextStyle(fontSize: 12)),
                                Text('التنبيه: ${fmtTime(sun.eveningAdhkarReminder)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('أذكار الصباح (قبل الشروق بنصف ساعة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        value: _morningAdhkarEnabled,
                        activeColor: AppConstants.tertiary,
                        onChanged: (val) async {
                          await _notifService.requestPermissions();
                          await _notifService.updateSettings(morningAdhkarEnabled: val);
                          setState(() => _morningAdhkarEnabled = val);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('أذكار المساء (قبل المغرب بنصف ساعة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        value: _eveningAdhkarEnabled,
                        activeColor: AppConstants.primary,
                        onChanged: (val) async {
                          await _notifService.requestPermissions();
                          await _notifService.updateSettings(eveningAdhkarEnabled: val);
                          setState(() => _eveningAdhkarEnabled = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                              label: const Text('تجربة إشعار الصباح', style: TextStyle(fontSize: 11)),
                              onPressed: () => _notifService.showTestAdhkarNotification('morning'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.nights_stay_outlined, size: 16),
                              label: const Text('تجربة إشعار المساء', style: TextStyle(fontSize: 11)),
                              onPressed: () => _notifService.showTestAdhkarNotification('evening'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
