import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/app_locale.dart';
import '../core/utils/hijri_calendar.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import 'friends_screen.dart';
import 'hijri_calendar_screen.dart';
import 'leaderboard_screen.dart';

class DailyWorshipScreen extends StatefulWidget {
  const DailyWorshipScreen({super.key});

  @override
  State<DailyWorshipScreen> createState() => _DailyWorshipScreenState();
}

class _DailyWorshipScreenState extends State<DailyWorshipScreen> {
  final SupabaseService _service = SupabaseService.instance;
  final NotificationService _notifService = NotificationService.instance;
  Map<String, bool> _todayStatus = {};
  int _hijriOffset = 0;
  int _activeTab = 0; // 0 = Daily Worship, 1 = Dashboard (Leaderboard)
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdated);
    _loadStatus();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdated);
    super.dispose();
  }

  void _onServiceUpdated() {
    if (mounted) _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final status = await _service.getTodayWorshipStatus();
    final offset = await _notifService.getHijriOffset();
    if (!mounted) return;
    setState(() {
      _todayStatus = status;
      _hijriOffset = offset;
      _loading = false;
    });
  }

  List<WorshipTaskModel> get _activeTasks =>
      SupabaseService.getTodayWorshipTasks(hijriOffset: _hijriOffset);

  int get _maxDailyPoints =>
      SupabaseService.getTodayMaxDailyPoints(hijriOffset: _hijriOffset);

  int get _earnedPoints {
    int sum = 0;
    final activeKeys = _activeTasks.map((e) => e.key).toSet();
    _todayStatus.forEach((k, v) {
      if (v && activeKeys.contains(k)) {
        final t = SupabaseService.findTaskByKey(k);
        if (t != null) sum += t.points;
      }
    });
    return sum;
  }

  Future<void> _openHijriCalendar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
    );
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _service.currentProfile;
    final maxPts = _maxDailyPoints;
    final earnedPts = _earnedPoints;
    final percent = maxPts > 0 ? (earnedPts / maxPts).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();
    final todayHijri = HijriCalendar.fromGregorian(now, offsetDays: _hijriOffset);
    final tomorrowHijri = HijriCalendar.fromGregorian(now.add(const Duration(days: 1)), offsetDays: _hijriOffset);

    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final tr = AppLocale.instance.tr;
    final activeBg = AppConstants.accentBg(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _activeTab == 0
              ? tr('الورد اليومي', 'Daily Worship')
              : tr('لوحة المتصدرين', 'Dashboard'),
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_activeTab == 1)
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: tr('الأصدقاء وطلبات الصداقة', 'Friends & Requests'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: tr('التقويم الهجري وتنبيهات الصيام', 'Hijri Calendar'),
            onPressed: _openHijriCalendar,
          ),
          if (_activeTab == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStatus,
            ),
        ],
      ),
      body: Column(
        children: [
          // Top segment switcher: Daily Worship | Dashboard
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        tr('الورد اليومي', 'Daily Worship'),
                        style: TextStyle(
                          color: _activeTab == 0 ? Colors.white : secondaryTxt,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    selected: _activeTab == 0,
                    selectedColor: activeBg,
                    backgroundColor: AppConstants.cardSurface(context),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                    onSelected: (_) => setState(() => _activeTab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        tr('لوحة المتصدرين', 'Dashboard'),
                        style: TextStyle(
                          color: _activeTab == 1 ? Colors.white : secondaryTxt,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    selected: _activeTab == 1,
                    selectedColor: activeBg,
                    backgroundColor: AppConstants.cardSurface(context),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                    onSelected: (_) => setState(() => _activeTab = 1),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 1
                ? const LeaderboardScreen(embedded: true)
                : (_loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadStatus,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                  // Hijri Date Strip
                  InkWell(
                    onTap: _openHijriCalendar,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppConstants.cardSurface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppConstants.borderColor(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppConstants.activeSurface(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              todayHijri.isFastingDay ? Icons.nightlight_round : Icons.calendar_month,
                              color: primaryTxt,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todayHijri.formattedArabic,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryTxt,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  todayHijri.isFastingDay
                                      ? 'اليوم: ${todayHijri.fastingReasonLabel}'
                                      : (tomorrowHijri.isFastingDay
                                          ? 'غداً: ${tomorrowHijri.fastingReasonLabel}'
                                          : 'التقويم الهجري وتنبيهات الصيام'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: (todayHijri.isFastingDay || tomorrowHijri.isFastingDay)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: secondaryTxt,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: secondaryTxt),
                        ],
                      ),
                    ),
                  ),

                  // Progress Banner
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
                            Text(
                              'إنجاز اليوم في الطاعات',
                              style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department, color: Colors.white, size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profile?.streakCount ?? 1} أيام',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$earnedPts / $maxPts نقطة',
                              style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(percent * 100).toInt()}%',
                              style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.18),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Clean Tasks Checklist — Header ONLY (no body/subtitle sentences)
                  ..._activeTasks.map((task) {
                    final isDone = _todayStatus[task.key] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppConstants.borderColor(context)),
                      ),
                      color: isDone ? AppConstants.activeSurface(context) : AppConstants.cardSurface(context),
                      child: ListTile(
                        leading: Checkbox(
                          value: isDone,
                          activeColor: AppConstants.accentBg(context),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (val) async {
                            await _service.toggleWorshipTask(task.key, val ?? false);
                            await _loadStatus();
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? secondaryTxt : primaryTxt,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppConstants.activeSurface(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${task.points} ن',
                            style: TextStyle(
                              color: isDone ? secondaryTxt : primaryTxt,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () async {
                          await _service.toggleWorshipTask(task.key, !isDone);
                          await _loadStatus();
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
