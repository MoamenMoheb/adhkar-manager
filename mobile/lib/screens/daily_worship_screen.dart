import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class DailyWorshipScreen extends StatefulWidget {
  const DailyWorshipScreen({super.key});

  @override
  State<DailyWorshipScreen> createState() => _DailyWorshipScreenState();
}

class _DailyWorshipScreenState extends State<DailyWorshipScreen> {
  final SupabaseService _service = SupabaseService.instance;
  Map<String, bool> _todayStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final status = await _service.getTodayWorshipStatus();
    setState(() {
      _todayStatus = status;
      _loading = false;
    });
  }

  int get _earnedPoints {
    int sum = 0;
    _todayStatus.forEach((k, v) {
      if (v) {
        final t = SupabaseService.worshipTasks.firstWhere((e) => e.key == k, orElse: () => const WorshipTaskModel(key: '', title: '', subtitle: '', points: 0, category: '', categoryName: '', icon: ''));
        sum += t.points;
      }
    });
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _service.currentProfile;
    final percent = (_earnedPoints / SupabaseService.totalMaxDailyPoints).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('الورد اليومي', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
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
                              '$_earnedPoints / ${SupabaseService.totalMaxDailyPoints} نقطة',
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
                  ...SupabaseService.worshipTasks.map((task) {
                    final isDone = _todayStatus[task.key] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDone ? AppConstants.secondary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      color: isDone ? AppConstants.secondary.withOpacity(0.06) : null,
                      child: ListTile(
                        leading: Checkbox(
                          value: isDone,
                          activeColor: AppConstants.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (val) async {
                            await _service.toggleWorshipTask(task.key, val ?? false);
                            await _loadStatus();
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(task.subtitle, style: const TextStyle(fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDone ? AppConstants.secondary.withOpacity(0.15) : AppConstants.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${task.points} ن',
                            style: TextStyle(
                              color: isDone ? AppConstants.secondary : AppConstants.primary,
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
