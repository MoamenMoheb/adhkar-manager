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
  int _morningOffsetMin = 30;
  int _eveningOffsetMin = 30;
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
    final morningOff = await _notifService.getMorningAdhkarOffsetMinutes();
    final eveningOff = await _notifService.getEveningAdhkarOffsetMinutes();
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
      _morningOffsetMin = morningOff;
      _eveningOffsetMin = eveningOff;
      _cityKey = cityKey;
      _eveningTime = TimeOfDay(hour: evTime[0], minute: evTime[1]);
      _viewYear = todayHijri.year;
      _viewMonth = todayHijri.month;
      _selectedDay = todayHijri;
      _loadingPrefs = false;
    });
  }

  Future<void> _updateAdhkarOffset({required bool isMorning, required int minutes}) async {
    final clamped = minutes.clamp(1, 180);
    await _notifService.requestPermissions();
    if (isMorning) {
      await _notifService.updateSettings(morningAdhkarOffsetMin: clamped);
      if (mounted) setState(() => _morningOffsetMin = clamped);
    } else {
      await _notifService.updateSettings(eveningAdhkarOffsetMin: clamped);
      if (mounted) setState(() => _eveningOffsetMin = clamped);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isMorning
                ? 'تم ضبط أذكار الصباح قبل الشروق بـ $clamped دقيقة'
                : 'تم ضبط أذكار المساء قبل المغرب بـ $clamped دقيقة',
          ),
        ),
      );
  }

  Future<void> _showCustomOffsetDialog({required bool isMorning}) async {
    final controller = TextEditingController(
      text: (isMorning ? _morningOffsetMin : _eveningOffsetMin).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isMorning ? 'توقيت أذكار الصباح' : 'توقيت أذكار المساء',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isMorning ? 'عدد الدقائق قبل الشروق' : 'عدد الدقائق قبل المغرب',
            hintText: 'مثال: ٢٠ أو ٣٠ أو ٦٠',
            suffixText: 'دقيقة',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 1 || parsed > 180) {
                return;
              }
              Navigator.pop(ctx, parsed);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _updateAdhkarOffset(isMorning: isMorning, minutes: result);
    }
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

    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final selectedBg = AppConstants.accentBg(context);

    int weekdayToGridIndex(int weekday) {
      if (weekday == DateTime.saturday) return 0;
      if (weekday == DateTime.sunday) return 1;
      return weekday + 1;
    }

    final firstLeadingEmpty = weekdayToGridIndex(monthDays.first.gregorian.weekday);

    return Scaffold(
      appBar: AppBar(
        title: Text('التقويم الهجري وصيام السنة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: Text('اليوم', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTxt)),
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
              gradient: AppConstants.heroGradient(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppConstants.borderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nightlight_round, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text('التاريخ الهجري اليوم', style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _changeOffset(-1),
                            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, color: Colors.white, size: 15)),
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
                            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, color: Colors.white, size: 15)),
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
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'اليوم: ${todayHijri.fastingReasonLabel}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else if (tomorrowHijri.isFastingDay) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'غداً: ${tomorrowHijri.fastingReasonLabel}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
            color: AppConstants.cardSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth, tooltip: 'الشهر السابق'),
                      Text(
                        '${HijriDate.monthNames[_viewMonth - 1]} $_viewYear هـ',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.bold, color: primaryTxt),
                      ),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth, tooltip: 'الشهر التالي'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة']
                        .map((label) => Expanded(
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: (label == 'إثنين' || label == 'خميس') ? FontWeight.bold : FontWeight.normal,
                                    color: (label == 'إثنين' || label == 'خميس') ? primaryTxt : secondaryTxt,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

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

                      Color bgColor = AppConstants.activeSurface(context);
                      Color borderColor = Colors.transparent;
                      if (isToday) {
                        bgColor = selectedBg;
                      } else if (isBeed) {
                        borderColor = primaryTxt.withOpacity(0.65);
                      } else if (isMonThu) {
                        borderColor = secondaryTxt.withOpacity(0.45);
                      }

                      if (isSelected && !isToday) {
                        borderColor = primaryTxt;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = dayObj),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? primaryTxt : borderColor,
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
                                  color: isToday ? Colors.white : primaryTxt,
                                ),
                              ),
                              Text(
                                '${dayObj.gregorian.day}/${dayObj.gregorian.month}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isToday ? Colors.white70 : secondaryTxt,
                                ),
                              ),
                              if (isBeed || isMonThu)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    isBeed ? Icons.brightness_3 : Icons.circle,
                                    size: isBeed ? 9 : 6,
                                    color: isToday ? Colors.white : (isBeed ? primaryTxt : secondaryTxt),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _legendChip(primaryTxt, 'الأيام البيض (١٣-١٤-١٥)'),
                      _legendChip(secondaryTxt, 'الإثنين والخميس'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_selectedDay != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: AppConstants.cardSurface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppConstants.borderColor(context)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDay!.formattedArabic,
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: primaryTxt),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الموافق ${_gregorianShort(_selectedDay!.gregorian)} ${_selectedDay!.gregorian.year} م',
                      style: TextStyle(fontSize: 12, color: secondaryTxt),
                    ),
                    if (_selectedDay!.occasionName != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_selectedDay!.occasionName!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTxt)),
                        backgroundColor: AppConstants.activeSurface(context),
                      ),
                    ],
                    if (_selectedDay!.isFastingDay) ...[
                      const SizedBox(height: 8),
                      Text(
                        'يوم صيام سُنّة: ${_selectedDay!.fastingReasonLabel}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 3. Fasting Reminder Settings
          Card(
            elevation: 0,
            color: AppConstants.cardSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تنبيهات وتذكير الصيام', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTxt)),
                  const Divider(height: 22),
                  if (_loadingPrefs)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('صيام الإثنين والخميس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt)),
                      value: _monThuEnabled,
                      onChanged: (val) async {
                        await _notifService.requestPermissions();
                        await _notifService.updateSettings(monThuEnabled: val);
                        setState(() => _monThuEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('صيام الأيام البيض (١٣، ١٤، ١٥ هـ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt)),
                      value: _ayyamBeedEnabled,
                      onChanged: (val) async {
                        await _notifService.requestPermissions();
                        await _notifService.updateSettings(ayyamBeedEnabled: val);
                        setState(() => _ayyamBeedEnabled = val);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time, color: primaryTxt),
                      title: Text('توقيت تذكير المساء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.activeSurface(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _eveningTime.format(context),
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTxt),
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
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Morning & Evening Adhkar Settings
          Builder(
            builder: (context) {
              final city = SunTimesCalculator.getCityByKey(_cityKey);
              final sun = SunTimesCalculator.calculate(today, city.lat, city.lng);
              final morningRem = sun.morningReminder(minutesBefore: _morningOffsetMin);
              final eveningRem = sun.eveningReminder(minutesBefore: _eveningOffsetMin);
              String fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

              return Card(
                elevation: 0,
                color: AppConstants.cardSurface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppConstants.borderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تنبيهات أذكار الصباح والمساء', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTxt)),
                      const SizedBox(height: 4),
                      Text(
                        'الصباح قبل الشروق بـ $_morningOffsetMin دقيقة • المساء قبل المغرب بـ $_eveningOffsetMin دقيقة',
                        style: TextStyle(fontSize: 11, color: secondaryTxt),
                      ),
                      const Divider(height: 22),
                      DropdownButtonFormField<String>(
                        value: city.key,
                        decoration: InputDecoration(
                          labelText: 'المدينة',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: SunTimesCalculator.cities
                            .map((c) => DropdownMenuItem(value: c.key, child: Text(c.nameAr, style: TextStyle(fontSize: 13, color: primaryTxt))))
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
                          color: AppConstants.activeSurface(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الشروق اليوم: ${fmtTime(sun.sunrise)}', style: TextStyle(fontSize: 12, color: secondaryTxt)),
                                Text('التنبيه: ${fmtTime(morningRem)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTxt)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المغرب اليوم: ${fmtTime(sun.sunset)}', style: TextStyle(fontSize: 12, color: secondaryTxt)),
                                Text('التنبيه: ${fmtTime(eveningRem)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTxt)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('أذكار الصباح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                        subtitle: Text('التنبيه قبل الشروق بـ $_morningOffsetMin دقيقة', style: TextStyle(fontSize: 11, color: secondaryTxt)),
                        value: _morningAdhkarEnabled,
                        onChanged: (val) async {
                          await _notifService.requestPermissions();
                          await _notifService.updateSettings(morningAdhkarEnabled: val);
                          setState(() => _morningAdhkarEnabled = val);
                        },
                      ),
                      _buildOffsetSelector(isMorning: true, currentMinutes: _morningOffsetMin, primaryTxt: primaryTxt, secondaryTxt: secondaryTxt),
                      const Divider(height: 20),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('أذكار المساء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                        subtitle: Text('التنبيه قبل المغرب بـ $_eveningOffsetMin دقيقة', style: TextStyle(fontSize: 11, color: secondaryTxt)),
                        value: _eveningAdhkarEnabled,
                        onChanged: (val) async {
                          await _notifService.requestPermissions();
                          await _notifService.updateSettings(eveningAdhkarEnabled: val);
                          setState(() => _eveningAdhkarEnabled = val);
                        },
                      ),
                      _buildOffsetSelector(isMorning: false, currentMinutes: _eveningOffsetMin, primaryTxt: primaryTxt, secondaryTxt: secondaryTxt),
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

  Widget _buildOffsetSelector({
    required bool isMorning,
    required int currentMinutes,
    required Color primaryTxt,
    required Color secondaryTxt,
  }) {
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
          buildPill('١٥ د', currentMinutes == 15, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 15)),
          buildPill('٢٠ د', currentMinutes == 20, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 20)),
          buildPill('٣٠ د', currentMinutes == 30, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 30)),
          buildPill('ساعة (٦٠ د)', currentMinutes == 60, () => _updateAdhkarOffset(isMorning: isMorning, minutes: 60)),
          buildPill(
            isCustom ? '$currentMinutes د' : 'تخصيص',
            isCustom,
            () => _showCustomOffsetDialog(isMorning: isMorning),
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
        Text(text, style: TextStyle(fontSize: 11, color: AppConstants.textSecondary(context))),
      ],
    );
  }
}
