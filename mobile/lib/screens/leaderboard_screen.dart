import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import 'friends_screen.dart';
import 'auth_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _service = SupabaseService.instance;
  bool _onlyFriends = false;
  String _timeframe = 'today'; // 'today', 'week', 'month', 'all'
  List<LeaderboardEntry> _entries = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loading = true;

  String get _userGender {
    return _service.currentProfile?.gender ??
        _service.currentUser?.userMetadata?['gender']?.toString() ??
        'male';
  }

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    if (_service.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _pendingRequests = [];
        _loading = false;
      });
      return;
    }
    final data = await _service.fetchLeaderboard(
      timeframe: _timeframe,
      onlyFriends: _onlyFriends,
      gender: _userGender,
    );
    final reqs = await _service.fetchFriendRequests();
    if (!mounted) return;
    setState(() {
      _entries = data;
      _pendingRequests = reqs;
      _loading = false;
    });
  }

  Future<void> _openFriendsManager() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
    await _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final selectedBg = AppConstants.accentBg(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة المتصدرين', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.group_add),
                tooltip: 'إضافة وإدارة الأصدقاء',
                onPressed: _openFriendsManager,
              ),
              if (_pendingRequests.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pendingRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: InkWell(
                onTap: _openFriendsManager,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppConstants.activeSurface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 18, color: primaryTxt),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لديك ${_pendingRequests.length} طلب صداقة جديد — اضغط للقبول أو الرفض',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTxt),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: secondaryTxt),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text('👥 أصدقائي', style: TextStyle(color: _onlyFriends ? Colors.white : secondaryTxt, fontWeight: FontWeight.bold))),
                    selected: _onlyFriends,
                    selectedColor: selectedBg,
                    backgroundColor: AppConstants.cardSurface(context),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                    onSelected: (val) {
                      setState(() => _onlyFriends = true);
                      _loadLeaderboard();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text('🌍 الترتيب العام', style: TextStyle(color: !_onlyFriends ? Colors.white : secondaryTxt, fontWeight: FontWeight.bold))),
                    selected: !_onlyFriends,
                    selectedColor: selectedBg,
                    backgroundColor: AppConstants.cardSurface(context),
                    side: BorderSide(color: AppConstants.borderColor(context)),
                    onSelected: (val) {
                      setState(() => _onlyFriends = false);
                      _loadLeaderboard();
                    },
                  ),
                ),
              ],
            ),
          ),

          if (!_onlyFriends && _service.currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.cardSurface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.borderColor(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _userGender == 'female' ? Icons.woman : Icons.man,
                      size: 18,
                      color: primaryTxt,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _userGender == 'female'
                          ? 'لوحة المتصدرات (النساء فقط)'
                          : 'لوحة المتصدرين (الرجال فقط)',
                      style: TextStyle(
                        color: primaryTxt,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _service.currentUser == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 52, color: secondaryTxt),
                              const SizedBox(height: 12),
                              Text(
                                'سجل دخولك للمنافسة وعرض لوحة الترتيب العام الخاصة بفئتك',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: primaryTxt, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()))
                                      .then((_) => _loadLeaderboard());
                                },
                                child: const Text('تسجيل الدخول / إنشاء حساب'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _entries.isEmpty
                    ? Center(
                        child: Text(
                          _onlyFriends ? 'لم تضف أصدقاء بعد للتنافس معهم' : 'لا يوجد متنافسون في هذه القائمة',
                          style: TextStyle(color: secondaryTxt),
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
                            color: isMe ? AppConstants.activeSurface(context) : AppConstants.cardSurface(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppConstants.borderColor(context)),
                            ),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: idx == 0 ? Colors.white : AppConstants.activeSurface(context),
                                    child: Text(
                                      '${item.rank}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: idx == 0 ? Colors.black : primaryTxt,
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
                                  Text(item.displayName, style: TextStyle(fontWeight: FontWeight.bold, color: primaryTxt)),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: selectedBg, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('أنت', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text('🔥 ${item.streakCount} يوم متتالي', style: TextStyle(fontSize: 12, color: secondaryTxt)),
                              trailing: Text(
                                '${item.points} نقطة',
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryTxt, fontSize: 14),
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
