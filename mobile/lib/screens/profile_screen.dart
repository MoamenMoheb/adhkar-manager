import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../services/supabase_service.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';
import 'hijri_calendar_screen.dart';
import '../services/app_update_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _service = SupabaseService.instance;
  String _appVersion = '...';
  bool _checkingUpdate = false;

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
    return ListTile(
      tileColor: AppConstants.secondary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: _checkingUpdate
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.system_update, color: AppConstants.secondary),
      title: const Text('تحديث التطبيق من الداخل', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('الإصدار الحالي: v$_appVersion • اضغط للتحقق من التحديثات', style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.refresh, size: 18),
      onTap: _checkUpdateManual,
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
                child: _buildUpdateTile(),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('كود الصداقة الخاص بك', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(profile?.friendCode ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppConstants.secondary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الصداقة بنجاح 📋')));
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PRIVACY SETTING CARD (Public vs Friends vs Private)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('خصوصية إنجازك في لوحة المتصدرين:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🌍 عام')),
                          selected: profile?.privacyLevel == 'public',
                          selectedColor: AppConstants.primary,
                          labelStyle: TextStyle(color: profile?.privacyLevel == 'public' ? Colors.white : null),
                          onSelected: (_) async {
                            await _service.updatePrivacyLevel('public');
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('👥 أصدقائي')),
                          selected: profile?.privacyLevel == 'friends',
                          selectedColor: AppConstants.primary,
                          labelStyle: TextStyle(color: profile?.privacyLevel == 'friends' ? Colors.white : null),
                          onSelected: (_) async {
                            await _service.updatePrivacyLevel('friends');
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🔒 خاص')),
                          selected: profile?.privacyLevel == 'private',
                          selectedColor: AppConstants.primary,
                          labelStyle: TextStyle(color: profile?.privacyLevel == 'private' ? Colors.white : null),
                          onSelected: (_) async {
                            await _service.updatePrivacyLevel('private');
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hijri Calendar & Fasting Reminders Shortcut
          ListTile(
            tileColor: AppConstants.primary.withOpacity(0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.calendar_month, color: AppConstants.primary),
            title: const Text('التقويم الهجري وتنبيهات الصيام', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تذكير الإثنين والخميس والأيام البيض (١٣، ١٤، ١٥)', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen()));
            },
          ),
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


