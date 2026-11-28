import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/app_locale.dart';
import '../core/utils/hijri_calendar.dart';
import '../core/utils/sun_times.dart';
import '../services/notification_service.dart';
import 'notification_settings_screen.dart';

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
    final todayHijri = HijriCalendar.fromGregorian(DateTime.now(), offsetDays: offset);
    if (!mounted) return;
    setState(() {
      _hijriOffset = offset;
      _viewYear = todayHijri.year;
      _viewMonth = todayHijri.month;
      _selectedDay = todayHijri;
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

          // 3. Notification Settings Shortcut (All alerts gathered in Settings)
          Card(
            elevation: 0,
            color: AppConstants.cardSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(Icons.notifications_active_outlined, color: AppConstants.secondary),
              title: Text(
                AppLocale.instance.tr('إعدادات تنبيهات الصيام والأذكار', 'Fasting & Adhkar Alert Settings'),
                style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt),
              ),
              subtitle: Text(
                AppLocale.instance.tr('تم تجميع كافة إعدادات الإشعارات في الإعدادات', 'All notification controls are unified in Settings'),
                style: TextStyle(fontSize: 11, color: secondaryTxt),
              ),
              trailing: Icon(Icons.chevron_right, color: secondaryTxt),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
                await _loadSettings();
              },
            ),
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
