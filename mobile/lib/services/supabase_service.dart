import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../core/utils/hijri_calendar.dart';

class SupabaseService extends ChangeNotifier {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;
  ProfileModel? currentProfile;
  User? get currentUser => client.auth.currentUser;

  static const List<WorshipTaskModel> worshipTasks = [
    WorshipTaskModel(
      key: 'fajr',
      title: 'صلاة الفجر',
      subtitle: 'في أول وقتها مع ركعتي الفجر',
      points: 10,
      category: 'prayers',
      categoryName: 'الصلوات المفروضة',
      icon: 'wb_twilight',
    ),
    WorshipTaskModel(
      key: 'dhuhr',
      title: 'صلاة الظهر',
      subtitle: 'الفريضة والسنن الرواتب القبلية والبعدية',
      points: 10,
      category: 'prayers',
      categoryName: 'الصلوات المفروضة',
      icon: 'light_mode',
    ),
    WorshipTaskModel(
      key: 'asr',
      title: 'صلاة العصر',
      subtitle: 'الصلاة الوسطى في أول وقتها',
      points: 10,
      category: 'prayers',
      categoryName: 'الصلوات المفروضة',
      icon: 'wb_sunny',
    ),
    WorshipTaskModel(
      key: 'maghrib',
      title: 'صلاة المغرب',
      subtitle: 'الفريضة وركعتا السُنّة البعدية',
      points: 10,
      category: 'prayers',
      categoryName: 'الصلوات المفروضة',
      icon: 'wb_twilight',
    ),
    WorshipTaskModel(
      key: 'isha',
      title: 'صلاة العشاء',
      subtitle: 'الفريضة وسُنّة العشاء وركعة الوتر',
      points: 10,
      category: 'prayers',
      categoryName: 'الصلوات المفروضة',
      icon: 'bedtime',
    ),
    WorshipTaskModel(
      key: 'qiyam',
      title: 'قيام الليل والتهجد',
      subtitle: 'ركعتان في جوف الليل والوتر وسؤال المغفرة',
      points: 30,
      category: 'nawafil',
      categoryName: 'النوافل والسنن',
      icon: 'nights_stay',
    ),
    WorshipTaskModel(
      key: 'morning_adhkar',
      title: 'أذكار الصباح',
      subtitle: 'حرز المسلم وحصنه المنيع طوال نهاره',
      points: 15,
      category: 'adhkar',
      categoryName: 'الأذكار المأثورة',
      icon: 'wb_sunny',
    ),
    WorshipTaskModel(
      key: 'evening_adhkar',
      title: 'أذكار المساء',
      subtitle: 'سكينة وطمأنينة وحفظ تام حتى الصباح',
      points: 15,
      category: 'adhkar',
      categoryName: 'الأذكار المأثورة',
      icon: 'nights_stay',
    ),
    WorshipTaskModel(
      key: 'quran_wird',
      title: 'الورد القرآني اليومي',
      subtitle: 'تلاوة جزء أو حزب بتدبر وحضور قلب',
      points: 25,
      category: 'quran',
      categoryName: 'القرآن الكريم',
      icon: 'menu_book',
    ),
    WorshipTaskModel(
      key: 'daily_sadaqah',
      title: 'صدقة اليوم',
      subtitle: 'إطعام، تفريج كربة، أو تبسم وكلمة طيبة',
      points: 20,
      category: 'charity',
      categoryName: 'البر والإنفاق',
      icon: 'volunteer_activism',
    ),
  ];

  static const int totalMaxDailyPoints = 155;

  static const WorshipTaskModel _fastingMonThuTemplate = WorshipTaskModel(
    key: 'fasting_mon_thu',
    title: 'صيام الإثنين والخميس',
    subtitle: 'تُعرض الأعمال يومي الإثنين والخميس فأحب أن يُعرض عملي وأنا صائم',
    points: 25,
    category: 'fasting',
    categoryName: 'صيام التطوع والسنة',
    icon: 'wb_twilight',
  );

  static const WorshipTaskModel _fastingAyyamBeedTemplate = WorshipTaskModel(
    key: 'fasting_ayyam_beed',
    title: 'صيام الأيام البيض (١٣-١٤-١٥)',
    subtitle: '',
    points: 30,
    category: 'fasting',
    categoryName: 'صيام التطوع والسنة',
    icon: 'brightness_3',
  );

  static List<WorshipTaskModel> getTodayWorshipTasks({int hijriOffset = 0, DateTime? date}) {
    final target = date ?? DateTime.now();
    final hijri = HijriCalendar.fromGregorian(target, offsetDays: hijriOffset);
    final List<WorshipTaskModel> list = List<WorshipTaskModel>.from(worshipTasks);

    if (hijri.isRecommendedMonThu) {
      list.add(WorshipTaskModel(
        key: _fastingMonThuTemplate.key,
        title: hijri.isMonday ? 'صيام يوم الإثنين (سُنّة)' : 'صيام يوم الخميس (سُنّة)',
        subtitle: _fastingMonThuTemplate.subtitle,
        points: _fastingMonThuTemplate.points,
        category: _fastingMonThuTemplate.category,
        categoryName: _fastingMonThuTemplate.categoryName,
        icon: _fastingMonThuTemplate.icon,
      ));
    }

    if (hijri.isRecommendedAyyamBeed) {
      list.add(WorshipTaskModel(
        key: _fastingAyyamBeedTemplate.key,
        title: 'صيام الأيام البيض (${hijri.day} ${hijri.monthName})',
        subtitle: _fastingAyyamBeedTemplate.subtitle,
        points: _fastingAyyamBeedTemplate.points,
        category: _fastingAyyamBeedTemplate.category,
        categoryName: _fastingAyyamBeedTemplate.categoryName,
        icon: _fastingAyyamBeedTemplate.icon,
      ));
    }

    return list;
  }

  static int getTodayMaxDailyPoints({int hijriOffset = 0, DateTime? date}) {
    return getTodayWorshipTasks(hijriOffset: hijriOffset, date: date)
        .fold<int>(0, (sum, t) => sum + t.points);
  }

  static WorshipTaskModel? findTaskByKey(String key, {int hijriOffset = 0}) {
    final all = [...worshipTasks, _fastingMonThuTemplate, _fastingAyyamBeedTemplate];
    for (final t in all) {
      if (t.key == key) return t;
    }
    return null;
  }

  Future<void> init() async {
    client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await loadCurrentProfile();
      } else {
        currentProfile = null;
      }
      notifyListeners();
    });

    if (currentUser != null) {
      await loadCurrentProfile();
    }
  }

  Future<ProfileModel?> loadCurrentProfile() async {
    if (currentUser == null) return null;
    try {
      final res = await client
          .from('profiles')
          .select('*')
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (res != null) {
        currentProfile = ProfileModel.fromJson(res);
      } else {
        currentProfile = ProfileModel(
          id: currentUser!.id,
          email: currentUser!.email ?? '',
          displayName: currentUser!.userMetadata?['display_name'] ?? 'مستخدم',
          avatarId: currentUser!.userMetadata?['avatar_id'] ?? 'm1',
          gender: currentUser!.userMetadata?['gender'] ?? 'male',
          friendCode: 'ADK-${currentUser!.id.substring(0, 4).toUpperCase()}',
          role: 'user',
          privacyLevel: 'public',
          totalPoints: 0,
          streakCount: 0,
        );
      }
      notifyListeners();
      return currentProfile;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  // ================= AUTH =================
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    required String gender,
    required String avatarId,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'https://moamenmoheb.github.io/adhkar-manager/auth-confirm.html',
      data: {
        'display_name': displayName,
        'full_name': displayName,
        'gender': gender,
        'avatar_id': avatarId,
      },
    );
    if (res.session != null) {
      await loadCurrentProfile();
    }
    return res;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await client.auth.signInWithPassword(email: email, password: password);
    await loadCurrentProfile();
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    currentProfile = null;
    notifyListeners();
  }

  Future<void> updatePrivacyLevel(String level) async {
    if (currentUser == null) return;
    await client
        .from('profiles')
        .update({'privacy_level': level, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', currentUser!.id);
    await loadCurrentProfile();
  }

  Future<void> updateAvatar(String avatarId) async {
    if (currentUser == null) return;
    await client
        .from('profiles')
        .update({'avatar_id': avatarId, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', currentUser!.id);
    await loadCurrentProfile();
  }

  Future<void> updateGender(String gender) async {
    if (currentUser == null) return;
    await client
        .from('profiles')
        .update({'gender': gender, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', currentUser!.id);
    await loadCurrentProfile();
  }

  // ================= WORSHIP =================
  String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<Map<String, bool>> getTodayWorshipStatus() async {
    final todayStr = getTodayDateString();
    final prefs = await SharedPreferences.getInstance();
    final localStr = prefs.getString('worship_$todayStr');
    Map<String, bool> map = {};
    if (localStr != null) {
      final decoded = jsonDecode(localStr) as Map<String, dynamic>;
      map = decoded.map((k, v) => MapEntry(k, v == true));
    }

    if (currentUser != null) {
      try {
        final res = await client
            .from('daily_worship_logs')
            .select('worship_key')
            .eq('user_id', currentUser!.id)
            .eq('log_date', todayStr);

        for (var row in (res as List)) {
          map[row['worship_key']] = true;
        }
        await prefs.setString('worship_$todayStr', jsonEncode(map));
      } catch (e) {
        debugPrint('Error fetching logs: $e');
      }
    }
    return map;
  }

  Future<void> toggleWorshipTask(String key, bool isCompleted) async {
    final todayStr = getTodayDateString();
    final prefs = await SharedPreferences.getInstance();
    final map = await getTodayWorshipStatus();
    if (isCompleted) {
      map[key] = true;
    } else {
      map.remove(key);
    }
    await prefs.setString('worship_$todayStr', jsonEncode(map));
    notifyListeners();

    if (currentUser != null) {
      try {
        final task = findTaskByKey(key);
        if (task == null) return;
        if (isCompleted) {
          await client.from('daily_worship_logs').upsert({
            'user_id': currentUser!.id,
            'log_date': todayStr,
            'worship_key': key,
            'points': task.points,
          }, onConflict: 'user_id,log_date,worship_key');
        } else {
          await client
              .from('daily_worship_logs')
              .delete()
              .eq('user_id', currentUser!.id)
              .eq('log_date', todayStr)
              .eq('worship_key', key);
        }
        await loadCurrentProfile();
      } catch (e) {
        debugPrint('Failed to sync worship to supabase: $e');
      }
    }
  }

  // ================= FRIENDSHIPS & SOCIAL =================
  Future<void> sendFriendRequestByCode(String code) async {
    if (currentUser == null) throw Exception('يجب تسجيل الدخول لإرسال طلب صداقة');
    final cleanCode = code.trim().toUpperCase();

    final target = await client
        .from('profiles')
        .select('id, display_name, friend_code')
        .eq('friend_code', cleanCode)
        .maybeSingle();

    if (target == null) throw Exception('لم يتم العثور على مستخدم بهذا الكود');
    if (target['id'] == currentUser!.id) throw Exception('لا يمكنك إرسال طلب صداقة لنفسك');

    await client.from('friendships').insert({
      'user_id': currentUser!.id,
      'friend_id': target['id'],
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> fetchFriendRequests() async {
    if (currentUser == null) return [];
    try {
      final res = await client
          .from('friendships')
          .select('id, user_id, status, sender:profiles!friendships_user_id_fkey(id, display_name, avatar_id, friend_code, total_points)')
          .eq('friend_id', currentUser!.id)
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      return [];
    }
  }

  Future<void> respondToFriendRequest(String id, bool accept) async {
    await client
        .from('friendships')
        .update({'status': accept ? 'accepted' : 'declined', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<List<ProfileModel>> fetchFriendsList() async {
    if (currentUser == null) return [];
    try {
      final res = await client
          .from('friendships')
          .select('user_id, friend_id, requester:profiles!friendships_user_id_fkey(*), recipient:profiles!friendships_friend_id_fkey(*)')
          .eq('status', 'accepted')
          .or('user_id.eq.${currentUser!.id},friend_id.eq.${currentUser!.id}');

      final List<ProfileModel> list = [];
      for (var f in res) {
        final profileData = f['user_id'] == currentUser!.id ? f['recipient'] : f['requester'];
        if (profileData != null) {
          list.add(ProfileModel.fromJson(profileData));
        }
      }
      return list;
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      return [];
    }
  }

  // ================= LEADERBOARD =================
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String timeframe,
    required bool onlyFriends,
    required String gender,
  }) async {
    try {
      final res = await client.rpc('get_leaderboard', params: {
        'p_timeframe': timeframe,
        'p_user_id': currentUser?.id,
        'p_only_friends': onlyFriends,
        'p_gender': gender,
      });

      if (res is List) {
        return res.map((item) => LeaderboardEntry.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('RPC get_leaderboard error: $e');
    }

    // Mock Demo Data fallback
    return [
      LeaderboardEntry(
        userId: '1',
        displayName: gender == 'male' ? 'عبدالرحمن محمد' : 'فاطمة الزهراء',
        avatarId: gender == 'male' ? 'm1' : 'f1',
        gender: gender,
        friendCode: 'ADK-7A8B',
        role: 'user',
        points: 145,
        streakCount: 14,
        rank: 1,
        isFriend: true,
      ),
      LeaderboardEntry(
        userId: '2',
        displayName: gender == 'male' ? 'أحمد الفاروق' : 'مريم أحمد',
        avatarId: gender == 'male' ? 'm2' : 'f2',
        gender: gender,
        friendCode: 'ADK-3X9P',
        role: 'user',
        points: 130,
        streakCount: 9,
        rank: 2,
        isFriend: true,
      ),
      LeaderboardEntry(
        userId: '3',
        displayName: gender == 'male' ? 'عمر بن الخطاب' : 'عائشة الصديقة',
        avatarId: gender == 'male' ? 'm3' : 'f3',
        gender: gender,
        friendCode: 'ADK-9K2L',
        role: 'user',
        points: 110,
        streakCount: 7,
        rank: 3,
        isFriend: false,
      ),
    ];
  }

  // ================= ADHKAR CRUD (ADMIN) =================
  Future<List<DhikrModel>> fetchAdhkar() async {
    final Map<String, DhikrModel> merged = {};

    // 1. Load bundled local Adhkar & Hadiths database (includes full Morning/Evening Azkar)
    try {
      final rawJson = await rootBundle.loadString('assets/data/adhkar_data.json');
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final items = decoded['adhkar'] as List<dynamic>? ?? [];
      for (final raw in items) {
        final model = DhikrModel.fromJson(raw as Map<String, dynamic>);
        if (model.status == 'active') {
          merged[model.id] = model;
        }
      }
    } catch (e) {
      debugPrint('Error loading bundled adhkar_data.json: $e');
    }

    // 2. Overlay / merge any remote Adhkar from Supabase if available
    try {
      final res = await client.from('adhkar').select('*').order('created_at', ascending: true);
      if (res is List && res.isNotEmpty) {
        for (final item in res) {
          final model = DhikrModel.fromJson(item as Map<String, dynamic>);
          if (model.status == 'active') {
            merged[model.id] = model;
          }
        }
      }
    } catch (e) {
      debugPrint('Remote adhkar table notice: $e');
    }

    if (merged.isNotEmpty) {
      return merged.values.toList();
    }

    // Minimal emergency fallback
    return [
      DhikrModel(
        id: 'dhikr-1',
        adminTitle: 'الكلمتان الحبيبتان إلى الرحمن',
        text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
        category: 'general',
        repeats: 100,
        virtue: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن.',
        status: 'active',
      ),
    ];
  }

  Future<void> saveDhikr(DhikrModel dhikr) async {
    await client.from('adhkar').upsert(dhikr.toJson());
    notifyListeners();
  }

  Future<void> deleteDhikr(String id) async {
    await client.from('adhkar').delete().eq('id', id);
    notifyListeners();
  }
}
