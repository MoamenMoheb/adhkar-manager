import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../services/supabase_service.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';
import 'hijri_calendar_screen.dart';
import 'friends_screen.dart';
import '../services/app_update_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _service = SupabaseService.instance;
  String _appVersion = '...';
  bool _checkingUpdate = false;
  bool _savingPrivacy = false;

  Future<void> _setPrivacy(String level) async {
    if (_savingPrivacy) return;
    setState(() => _savingPrivacy = true);
    try {
      await _service.updatePrivacyLevel(level);
      if (!mounted) return;
      final label = level == 'public'
          ? 'عام (للجميع)'
          : (level == 'friends' ? 'أصدقائي فقط' : 'خاص (مخفي)');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('تم تحديث خصوصية النقاط إلى: $label')),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('تعذر تحديث الخصوصية: $e')),
        );
    } finally {
      if (mounted) setState(() => _savingPrivacy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    AppUpdateService.instance.getCurrentVersion().then((v) {
      if (mounted) setState(() => _appVersion = v);
    });
  }

  Future<void> _checkUpdateManual() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final update = await AppUpdateService.instance.checkForUpdate(force: true);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    if (update != null) {
      await AppUpdateService.instance.showUpdateDialog(context, update);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أنت تستخدم أحدث إصدار من التطبيق (v$_appVersion) ✅')),
      );
    }
  }

  Widget _buildUpdateTile() {
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    return ListTile(
      tileColor: AppConstants.cardSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppConstants.borderColor(context)),
      ),
      leading: _checkingUpdate
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.system_update, color: primaryTxt),
      title: Text('تحديث التطبيق من الداخل', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTxt)),
      subtitle: Text('الإصدار الحالي: v$_appVersion • اضغط للتحقق من التحديثات', style: TextStyle(fontSize: 11, color: secondaryTxt)),
      trailing: Icon(Icons.refresh, size: 18, color: secondaryTxt),
      onTap: _checkUpdateManual,
    );
  }

  Widget _buildFixedPrayerNotifTile() {
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    return ValueListenableBuilder<bool>(
      valueListenable: NotificationService.instance.fixedPrayerNotifNotifier,
      builder: (context, isFixedEnabled, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.cardSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.borderColor(context)),
          ),
          child: SwitchListTile(
            secondary: Icon(Icons.push_pin_outlined, color: primaryTxt),
            title: Text(
              'إشعار الصلاة القادمة الدائم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt),
            ),
            subtitle: Text(
              isFixedEnabled
                  ? 'مفعل: ثابت في شريط الإشعارات لا يُزال بالسحب'
                  : 'معطل: فعّله لعرض العد التنازلي للصلاة القادمة',
              style: TextStyle(fontSize: 11, color: secondaryTxt),
            ),
            value: isFixedEnabled,
            onChanged: (val) async {
              await NotificationService.instance.requestPermissions();
              await NotificationService.instance.setFixedPrayerNotifEnabled(val);
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? 'تم تفعيل الإشعار الثابت للصلاة القادمة 📌'
                          : 'تم إيقاف الإشعار الثابت للصلاة القادمة',
                    ),
                  ),
                );
            },
          ),
        );
      },
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر صورتك الرمزية (20 شخصية إسلامية)', style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: '🚹 صور الرجال (10)'),
                          Tab(text: '🚺 صور النساء (10)'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 10 Male Avatars Grid
                            GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: AppConstants.maleAvatars.length,
                              itemBuilder: (context, idx) {
                                final av = AppConstants.maleAvatars[idx];
                                return InkWell(
                                  onTap: () async {
                                    await _service.updateAvatar(av['id']!);
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: Image.asset(av['asset']!, width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                );
                              },
                            ),
                            // 10 Female Avatars Grid
                            GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: AppConstants.femaleAvatars.length,
                              itemBuilder: (context, idx) {
                                final av = AppConstants.femaleAvatars[idx];
                                return InkWell(
                                  onTap: () async {
                                    await _service.updateAvatar(av['id']!);
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: Image.asset(av['asset']!, width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _service.currentProfile;
    final user = _service.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('سجل دخولك لحفظ نقاطك والتنافس مع أصدقائك'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())).then((_) => setState(() {}));
                },
                child: const Text('تسجيل الدخول / إنشاء حساب'),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildFixedPrayerNotifTile(),
                    const SizedBox(height: 12),
                    _buildUpdateTile(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الملف الشخصي', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + Name Card
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: Image.asset(
                          'assets/avatars/${profile?.avatarId ?? "m1"}.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppConstants.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(profile?.displayName ?? '', style: GoogleFonts.ibmPlexSansArabic(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (profile?.isAdmin == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                        child: const Text('⭐ Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                      ),
                    ],
                  ],
                ),
                Text(profile?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Friend Code Share Card
          Card(
            color: AppConstants.cardSurface(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كود الصداقة الخاص بك', style: TextStyle(color: AppConstants.textSecondary(context), fontSize: 12)),
                      Text(profile?.friendCode ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimary(context))),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppConstants.textPrimary(context)),
                    onPressed: () {
                      final code = profile?.friendCode ?? '';
                      if (code.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: code));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الصداقة بنجاح 📋')));
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PRIVACY SETTING CARD (Public vs Friends vs Private)
          Builder(
            builder: (context) {
              final currentPrivacy = profile?.privacyLevel ?? 'public';
              final primaryTxt = AppConstants.textPrimary(context);
              final secondaryTxt = AppConstants.textSecondary(context);
              final isDark = AppConstants.isDark(context);

              final String privacyDesc = currentPrivacy == 'public'
                  ? '🌍 عام: نقاطك وترتيبك يظهران للجميع في لوحة الصدارة العامة (ضمن نفس الجنس) وللأصدقاء.'
                  : (currentPrivacy == 'friends'
                      ? '👥 أصدقائي: نقاطك وترتيبك يظهران لأصدقائك المقبولين فقط ولا يظهران في الترتيب العام.'
                      : '🔒 خاص: نقاطك وترتيبك مخفيان تماماً عن الجميع ولن يظهرا في أي لوحة صدارة.');

              Widget buildPrivacyOption(String level, String label, IconData icon) {
                final selected = currentPrivacy == level;
                final activeBg = isDark ? const Color(0xFFF3F4F6) : AppConstants.primary;
                final activeFg = isDark ? const Color(0xFF0E1117) : Colors.white;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _savingPrivacy ? null : () => _setPrivacy(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected ? activeBg : AppConstants.activeSurface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? activeBg : AppConstants.borderColor(context),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 15, color: selected ? activeFg : secondaryTxt),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                color: selected ? activeFg : secondaryTxt,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Card(
                color: AppConstants.cardSurface(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppConstants.borderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('خصوصية إنجازك في لوحة المتصدرين:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt)),
                          if (_savingPrivacy)
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          buildPrivacyOption('public', 'عام', Icons.public),
                          const SizedBox(width: 6),
                          buildPrivacyOption('friends', 'أصدقائي', Icons.group),
                          const SizedBox(width: 6),
                          buildPrivacyOption('private', 'خاص', Icons.lock),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppConstants.activeSurface(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppConstants.borderColor(context)),
                        ),
                        child: Text(
                          privacyDesc,
                          style: TextStyle(fontSize: 11, color: primaryTxt, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Friends & Requests Shortcut
          ListTile(
            tileColor: AppConstants.cardSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            leading: Icon(Icons.group_add, color: AppConstants.textPrimary(context)),
            title: Text('الأصدقاء وطلبات الصداقة', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary(context))),
            subtitle: Text('إضافة صديق، قبول أو رفض الطلبات، وإزالة الأصدقاء', style: TextStyle(fontSize: 11, color: AppConstants.textSecondary(context))),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppConstants.textSecondary(context)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
            },
          ),
          const SizedBox(height: 16),

          // Hijri Calendar & Fasting Reminders Shortcut
          ListTile(
            tileColor: AppConstants.cardSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            leading: Icon(Icons.calendar_month, color: AppConstants.textPrimary(context)),
            title: Text('التقويم الهجري وتنبيهات الصيام', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary(context))),
            subtitle: Text('تذكير الإثنين والخميس والأيام البيض (١٣، ١٤، ١٥)', style: TextStyle(fontSize: 11, color: AppConstants.textSecondary(context))),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppConstants.textSecondary(context)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen()));
            },
          ),
          const SizedBox(height: 16),

          // Fixed Next Prayer Notification Toggle
          _buildFixedPrayerNotifTile(),
          const SizedBox(height: 16),

          // In-app Update Check Tile
          _buildUpdateTile(),
          const SizedBox(height: 16),

          // Admin Dashboard Button (Only if user is Admin)
          if (profile?.isAdmin == true) ...[
            ListTile(
              tileColor: Colors.amber.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              title: const Text('لوحة تحكم المسؤول (إدارة الأذكار)', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],

          // Sign Out
          ListTile(
            tileColor: Colors.red.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await _service.signOut();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}


