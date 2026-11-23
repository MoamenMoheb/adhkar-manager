import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String gender,
    required String avatarId,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'full_name': displayName,
        'gender': gender,
        'avatar_id': avatarId,
      },
    );
    if (res.user != null) {
      await loadCurrentProfile();
    }
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
        final task = worshipTasks.firstWhere((t) => t.key == key);
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
    try {
      final res = await client.from('adhkar').select('*').order('created_at', ascending: true);
      if (res is List && res.isNotEmpty) {
        return res.map((item) => DhikrModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching adhkar: $e');
    }

    // Default static seed list
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
      DhikrModel(
        id: 'dhikr-2',
        adminTitle: 'أحب الكلام إلى الله (الباقيات الصالحات)',
        text: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
        category: 'general',
        repeats: 33,
        virtue: 'أحب إلى رسول الله ﷺ مما طلعت عليه الشمس.',
        status: 'active',
      ),
      DhikrModel(
        id: 'dhikr-3',
        adminTitle: 'حرز اليوم وعتق الرقاب',
        text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        category: 'morning_evening',
        repeats: 100,
        virtue: 'من قالها مائة مرة كانت له عدل عشر رقاب، ومائة حسنة، ومحيت عنه مائة سيئة.',
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
