import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _service = SupabaseService.instance;
  bool _onlyFriends = false;
  String _selectedGender = 'male'; // 'male' or 'female'
  String _timeframe = 'today'; // 'today', 'week', 'month', 'all'
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedGender = _service.currentProfile?.gender ?? 'male';
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    final data = await _service.fetchLeaderboard(
      timeframe: _timeframe,
      onlyFriends: _onlyFriends,
      gender: _selectedGender,
    );
    setState(() {
      _entries = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة المتصدرين', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scope Tabs: Friends vs Global
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('👥 أصدقائي')),
                    selected: _onlyFriends,
                    selectedColor: AppConstants.primary,
                    labelStyle: TextStyle(color: _onlyFriends ? Colors.white : null, fontWeight: FontWeight.bold),
                    onSelected: (val) {
                      setState(() => _onlyFriends = true);
                      _loadLeaderboard();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('🌍 الترتيب العام')),
                    selected: !_onlyFriends,
                    selectedColor: AppConstants.primary,
                    labelStyle: TextStyle(color: !_onlyFriends ? Colors.white : null, fontWeight: FontWeight.bold),
                    onSelected: (val) {
                      setState(() => _onlyFriends = false);
                      _loadLeaderboard();
                    },
                  ),
                ),
              ],
            ),
          ),

          // SEPARATE GENDER DASHBOARD TABS (Male vs Female)
          if (!_onlyFriends) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedGender = 'male');
                          _loadLeaderboard();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'male' ? AppConstants.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '🚹 المتصدرون (رجال)',
                              style: TextStyle(
                                color: _selectedGender == 'male' ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedGender = 'female');
                          _loadLeaderboard();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'female' ? AppConstants.secondary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '🚺 المتصدرات (نساء)',
                              style: TextStyle(
                                color: _selectedGender == 'female' ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Leaderboard Entries
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Text(
                          _onlyFriends ? 'لم تضف أصدقاء بعد للتنافس معهم' : 'لا يوجد متنافسون في هذه القائمة',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, idx) {
                          final item = _entries[idx];
                          final isMe = _service.currentUser != null && item.userId == _service.currentUser!.id;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: isMe ? AppConstants.primary.withOpacity(0.08) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isMe ? AppConstants.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: idx == 0 ? Colors.amber : (idx == 1 ? Colors.grey[400] : (idx == 2 ? Colors.brown[300] : Colors.grey[200])),
                                    child: Text(
                                      '${item.rank}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: idx < 3 ? Colors.black : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.asset(
                                      'assets/avatars/${item.avatarId}.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: AppConstants.primary, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('أنت', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text('🔥 ${item.streakCount} يوم متتالي', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                              trailing: Text(
                                '${item.points} نقطة',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primary, fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
