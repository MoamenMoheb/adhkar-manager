import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/hijri_calendar.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import 'hijri_calendar_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('الورد اليومي', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'التقويم الهجري وتنبيهات الصيام',
            onPressed: _openHijriCalendar,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatus,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Hijri Date & Fasting Reminder Strip
                  InkWell(
                    onTap: _openHijriCalendar,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: todayHijri.isFastingDay
                            ? AppConstants.tertiary.withOpacity(0.14)
                            : AppConstants.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: todayHijri.isFastingDay
                              ? AppConstants.tertiary.withOpacity(0.55)
                              : AppConstants.primary.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: todayHijri.isFastingDay ? AppConstants.tertiary : AppConstants.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              todayHijri.isFastingDay ? Icons.nightlight_round : Icons.calendar_month,
                              color: Colors.white,
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
                                    color: AppConstants.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  todayHijri.isFastingDay
                                      ? '🌙 اليوم ${todayHijri.fastingReasonLabel} (مضاف لنقاط اليوم!)'
                                      : (tomorrowHijri.isFastingDay
                                          ? '🔔 تذكير: غداً ${tomorrowHijri.fastingReasonLabel}'
                                          : 'اضغط لفتح التقويم الهجري وتنبيهات الصيام'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: (todayHijri.isFastingDay || tomorrowHijri.isFastingDay)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: todayHijri.isFastingDay
                                        ? const Color(0xFF925E00)
                                        : AppConstants.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // Progress Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.primary, AppConstants.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppConstants.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profile?.streakCount ?? 1} أيام متتالية',
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
                              style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tasks Checklist
                  ..._activeTasks.map((task) {
                    final isDone = _todayStatus[task.key] == true;
                    final isFastingTask = task.category == 'fasting';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDone
                              ? AppConstants.secondary.withOpacity(0.4)
                              : (isFastingTask
                                  ? AppConstants.tertiary.withOpacity(0.55)
                                  : Colors.grey.withOpacity(0.2)),
                          width: isFastingTask && !isDone ? 1.5 : 1,
                        ),
                      ),
                      color: isDone
                          ? AppConstants.secondary.withOpacity(0.06)
                          : (isFastingTask ? AppConstants.tertiary.withOpacity(0.07) : null),
                      child: ListTile(
                        leading: Checkbox(
                          value: isDone,
                          activeColor: isFastingTask ? AppConstants.tertiary : AppConstants.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (val) async {
                            await _service.toggleWorshipTask(task.key, val ?? false);
                            await _loadStatus();
                          },
                        ),
                        title: Row(
                          children: [
                            if (isFastingTask) ...[
                              const Icon(Icons.nightlight_round, size: 16, color: AppConstants.tertiary),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(task.subtitle, style: const TextStyle(fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppConstants.secondary.withOpacity(0.15)
                                : (isFastingTask
                                    ? AppConstants.tertiary.withOpacity(0.18)
                                    : AppConstants.primary.withOpacity(0.08)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${task.points} ن',
                            style: TextStyle(
                              color: isDone
                                  ? AppConstants.secondary
                                  : (isFastingTask ? const Color(0xFF925E00) : AppConstants.primary),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
