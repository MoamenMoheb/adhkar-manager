import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/app_locale.dart';
import '../services/app_update_service.dart';
import '../services/supabase_service.dart';
import 'azan_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  static const MethodChannel _permChannel =
      MethodChannel('com.moamenmoheb.adhkar_sanctuary/app_permissions');

  final SupabaseService _service = SupabaseService.instance;
  String _appVersion = '...';
  bool _checkingUpdate = false;

  bool _notifGranted = true;
  bool _locationGranted = false;
  bool _overlayGranted = false;
  bool _exactAlarmGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_onServiceChanged);
    AppUpdateService.instance.getCurrentVersion().then((v) {
      if (mounted) setState(() => _appVersion = v);
    });
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final res = await _permChannel.invokeMapMethod<String, dynamic>('getPermissionsStatus');
      if (!mounted || res == null) return;
      setState(() {
        _notifGranted = (res['notifications'] as bool?) ?? true;
        _locationGranted = (res['location'] as bool?) ?? false;
        _overlayGranted = (res['overlay'] as bool?) ?? false;
        _exactAlarmGranted = (res['exactAlarms'] as bool?) ?? true;
      });
    } catch (_) {}
  }

  Future<void> _handlePermissionToggle(String key, bool currentGranted) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (key == 'notifications') {
        await _permChannel.invokeMethod(currentGranted ? 'openNotificationSettings' : 'requestNotifications');
      } else if (key == 'location') {
        await _permChannel.invokeMethod(currentGranted ? 'openAppDetails' : 'requestLocation');
      } else if (key == 'overlay') {
        await _permChannel.invokeMethod('openOverlaySettings');
      } else if (key == 'exactAlarms') {
        await _permChannel.invokeMethod('openExactAlarmSettings');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _refreshPermissions();
    } catch (_) {}
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
      final tr = AppLocale.instance.tr;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr("أنت تستخدم أحدث إصدار من التطبيق", "You are using the latest version")} (v$_appVersion)',
          ),
        ),
      );
    }
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool granted,
    required String permKey,
    required Color accentEmerald,
    required Color primaryTxt,
    required Color secondaryTxt,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: granted ? accentEmerald : AppConstants.tertiary),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: secondaryTxt)),
      trailing: Switch(
        value: granted,
        activeColor: accentEmerald,
        onChanged: (_) => _handlePermissionToggle(permKey, granted),
      ),
      onTap: () => _handlePermissionToggle(permKey, granted),
      isThreeLine: false,
      visualDensity: VisualDensity.compact,
      dense: false,
      // Keep subtitle concise; allow add OR remove directly from system settings
      selected: false,
      splashColor: accentEmerald.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // Accessibility hint via tooltip on action not needed since Switch indicates state
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocale.instance.tr;
    final isAr = AppLocale.instance.isAr;
    final isDark = AppConstants.isDark(context);
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final accentEmerald = isDark ? const Color(0xFF10B981) : AppConstants.secondary;
    final profile = _service.currentProfile;
    final user = _service.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('الإعدادات', 'Settings'),
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. My Account Card
          Card(
            color: AppConstants.cardSurface(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppConstants.activeSurface(context),
                backgroundImage: user != null
                    ? AssetImage('assets/avatars/${profile?.avatarId ?? "m1"}.png')
                    : null,
                child: user == null
                    ? Icon(Icons.person_outline, color: primaryTxt, size: 24)
                    : null,
              ),
              title: Text(
                user != null
                    ? (profile?.displayName ?? tr('حسابي', 'My Account'))
                    : tr('حسابي (غير مسجل الدخول)', 'My Account (Signed Out)'),
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: primaryTxt,
                ),
              ),
              subtitle: Text(
                user != null
                    ? (profile?.email ?? tr('إدارة الحساب، الأصدقاء، والخصوصية', 'Manage profile, friends & privacy'))
                    : tr('اضغط لتسجيل الدخول ومزامنة نقاطك مع الأصدقاء', 'Tap to sign in and sync points with friends'),
                style: TextStyle(fontSize: 11, color: secondaryTxt),
              ),
              trailing: Icon(Icons.chevron_right, color: secondaryTxt),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 2. App Language Switch (Arabic / English)
          Card(
            color: AppConstants.cardSurface(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: accentEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr('لغة التطبيق', 'App Language'),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryTxt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'العربية',
                              style: TextStyle(
                                color: isAr ? Colors.white : secondaryTxt,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          selected: isAr,
                          selectedColor: accentEmerald,
                          backgroundColor: AppConstants.activeSurface(context),
                          side: BorderSide(color: AppConstants.borderColor(context)),
                          onSelected: (_) => AppLocale.instance.setLanguage('ar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'English',
                              style: TextStyle(
                                color: !isAr ? Colors.white : secondaryTxt,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          selected: !isAr,
                          selectedColor: accentEmerald,
                          backgroundColor: AppConstants.activeSurface(context),
                          side: BorderSide(color: AppConstants.borderColor(context)),
                          onSelected: (_) => AppLocale.instance.setLanguage('en'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Unified Notification Settings Hub
          Card(
            color: AppConstants.cardSurface(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: accentEmerald),
                  title: Text(
                    tr('إعدادات الإشعارات الشاملة', 'All Notification Settings'),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryTxt,
                    ),
                  ),
                  subtitle: Text(
                    tr(
                      'الإشعار الثابت، تنبيهات الصلوات، الأذكار، الصيام، والتقويم',
                      'Sticky prayer countdown, prayer alerts, Adhkar & fasting',
                    ),
                    style: TextStyle(fontSize: 11, color: secondaryTxt),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryTxt),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: AppConstants.borderColor(context)),
                ListTile(
                  leading: Icon(Icons.music_note_outlined, color: accentEmerald),
                  title: Text(
                    tr('شاشة الأذان وأصوات المؤذنين', 'Azan Wall Screen & Voices'),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryTxt,
                    ),
                  ),
                  subtitle: Text(
                    tr(
                      'الظهور فوق التطبيقات، ١٥ صوت مؤذن، و٤ خلفيات إسلامية',
                      'Display over apps, 15 Muezzin voices & 4 mosque themes',
                    ),
                    style: TextStyle(fontSize: 11, color: secondaryTxt),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryTxt),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AzanSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. App Permissions Manager (Add / Remove directly)
          Card(
            color: AppConstants.cardSurface(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('صلاحيات التطبيق (إضافة أو إزالة)', 'App Permissions (Add / Remove)'),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryTxt,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, size: 18, color: secondaryTxt),
                        tooltip: tr('تحديث الحالة', 'Refresh'),
                        onPressed: _refreshPermissions,
                      ),
                    ],
                  ),
                  Text(
                    tr(
                      'اضغط على أي صلاحية لمنحها أو فتح إعدادات النظام لإلغائها',
                      'Tap any permission to grant it or open system settings to revoke',
                    ),
                    style: TextStyle(fontSize: 11, color: secondaryTxt),
                  ),
                  const Divider(height: 18),
                  _buildPermissionRow(
                    icon: Icons.notifications_outlined,
                    title: tr('صلاحية الإشعارات', 'Notifications Permission'),
                    subtitle: _notifGranted
                        ? tr('مفعّلة • لتلقي تنبيهات الصلاة والأذكار', 'Enabled • Receive prayer & Adhkar alerts')
                        : tr('معطلة • اضغط للسماح بالإشعارات', 'Disabled • Tap to enable'),
                    granted: _notifGranted,
                    permKey: 'notifications',
                    accentEmerald: accentEmerald,
                    primaryTxt: primaryTxt,
                    secondaryTxt: secondaryTxt,
                  ),
                  _buildPermissionRow(
                    icon: Icons.location_on_outlined,
                    title: tr('صلاحية الموقع (GPS)', 'Location Permission (GPS)'),
                    subtitle: _locationGranted
                        ? tr('مفعّلة • لتحديد اتجاه القبلة بدقة', 'Enabled • Required for Qibla compass')
                        : tr('معطلة • مطلوبة لتشغيل بوصلة القبلة', 'Disabled • Required for Qibla'),
                    granted: _locationGranted,
                    permKey: 'location',
                    accentEmerald: accentEmerald,
                    primaryTxt: primaryTxt,
                    secondaryTxt: secondaryTxt,
                  ),
                  _buildPermissionRow(
                    icon: Icons.layers_outlined,
                    title: tr('الظهور فوق التطبيقات', 'Display Over Other Apps'),
                    subtitle: _overlayGranted
                        ? tr('مفعّلة • لعرض شاشة الأذان الكاملة', 'Enabled • Shows full-screen Azan wall')
                        : tr('معطلة • لعرض شاشة الأذان فوق الشاشة', 'Disabled • Tap to allow overlay'),
                    granted: _overlayGranted,
                    permKey: 'overlay',
                    accentEmerald: accentEmerald,
                    primaryTxt: primaryTxt,
                    secondaryTxt: secondaryTxt,
                  ),
                  _buildPermissionRow(
                    icon: Icons.alarm_on_outlined,
                    title: tr('المنبهات الدقيقة (Exact Alarms)', 'Exact Alarms Permission'),
                    subtitle: _exactAlarmGranted
                        ? tr('مفعّلة • لضبط انتقال الصلاة في وقتها', 'Enabled • Accurate prayer & Azan timing')
                        : tr('معطلة • يُنصح بتفعيلها لدقة الأذان', 'Disabled • Recommended for exact Azan'),
                    granted: _exactAlarmGranted,
                    permKey: 'exactAlarms',
                    accentEmerald: accentEmerald,
                    primaryTxt: primaryTxt,
                    secondaryTxt: secondaryTxt,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. In-App Update Tile
          ListTile(
            tileColor: AppConstants.cardSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppConstants.borderColor(context)),
            ),
            leading: _checkingUpdate
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.system_update, color: primaryTxt),
            title: Text(
              tr('تحديث التطبيق من الداخل', 'Check for App Updates'),
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryTxt),
            ),
            subtitle: Text(
              '${tr("الإصدار الحالي:", "Current version:")} v$_appVersion',
              style: TextStyle(fontSize: 11, color: secondaryTxt),
            ),
            trailing: Icon(Icons.refresh, size: 18, color: secondaryTxt),
            onTap: _checkUpdateManual,
          ),
        ],
      ),
    );
  }
}
