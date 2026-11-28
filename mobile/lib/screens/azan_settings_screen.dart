import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/app_locale.dart';
import '../core/utils/sun_times.dart';
import '../services/azan_audio_service.dart';
import '../services/notification_service.dart';

class AzanSettingsScreen extends StatefulWidget {
  const AzanSettingsScreen({super.key});

  @override
  State<AzanSettingsScreen> createState() => _AzanSettingsScreenState();
}

class _AzanSettingsScreenState extends State<AzanSettingsScreen> with WidgetsBindingObserver {
  final NotificationService _notif = NotificationService.instance;
  final AzanAudioService _audio = AzanAudioService.instance;

  bool _loading = true;
  bool _overlayEnabled = false;
  bool _hasOverlayPerm = false;
  bool _vibrate = false;
  String _wallpaperKey = 'wall_makkah';
  String _soundMode = 'azan';
  String _cityName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionOnResume();
    }
  }

  Future<void> _refreshPermissionOnResume() async {
    final hasPerm = await _notif.canDrawOverlays();
    if (!mounted) return;
    if (hasPerm && !_hasOverlayPerm) {
      await _notif.setAzanOverlayEnabled(true);
      if (!mounted) return;
      setState(() {
        _hasOverlayPerm = true;
        _overlayEnabled = true;
      });
    } else {
      setState(() => _hasOverlayPerm = hasPerm);
    }
  }

  Future<void> _loadState() async {
    final overlayEnabled = await _notif.isAzanOverlayEnabled();
    final hasPerm = await _notif.canDrawOverlays();
    final vibrate = await _notif.isAzanOverlayVibrate();
    final wallpaper = await _notif.getAzanWallpaperKey();
    final sound = await _notif.getPrayerSoundMode();
    final cityKey = await _notif.getSelectedCityKey();
    final city = SunTimesCalculator.getCityByKey(cityKey);

    if (!mounted) return;
    setState(() {
      _overlayEnabled = overlayEnabled;
      _hasOverlayPerm = hasPerm;
      _vibrate = vibrate;
      _wallpaperKey = wallpaper;
      _soundMode = sound;
      _cityName = city.nameAr;
      _loading = false;
    });
  }

  Future<void> _toggleOverlay(bool val) async {
    if (val) {
      final hasPerm = await _notif.canDrawOverlays();
      if (!hasPerm) {
        await _notif.requestOverlayPermission();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('يرجى تفعيل إذن الظهور فوق التطبيقات ثم العودة'),
            ),
          );
        return;
      }
    }
    await _notif.setAzanOverlayEnabled(val);
    if (!mounted) return;
    setState(() => _overlayEnabled = val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDark(context);
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final accentEmerald = isDark ? const Color(0xFF10B981) : AppConstants.secondary;
    final isAr = AppLocale.instance.isAr;
    final tr = AppLocale.instance.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('إعدادات الأذان والشاشة الكاملة', 'Azan Screen & Voice Settings'),
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      // 1. Display Over Apps / Lockscreen Wall Screen
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConstants.cardSurface(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppConstants.borderColor(context)),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(Icons.layers_outlined, color: accentEmerald),
                              title: Text(
                                tr('عرض شاشة الأذان فوق التطبيقات', 'Display Azan Over Apps'),
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryTxt,
                                ),
                              ),
                              subtitle: Text(
                                _overlayEnabled && _hasOverlayPerm
                                    ? tr('مفعّل: تظهر شاشة إسلامية كاملة مع القبلة وكتم الصوت وإغلاق', 'Enabled: shows full Islamic screen with Qibla, Mute & Cancel')
                                    : (_hasOverlayPerm
                                        ? tr('معطل: فعّله لظهور شاشة الأذان التلقائية عند دخول الوقت', 'Disabled: enable to show full-screen Azan at prayer time')
                                        : tr('يحتاج إلى منح إذن الظهور فوق التطبيقات الأخرى', 'Requires Display Over Other Apps permission')),
                                style: TextStyle(fontSize: 11, color: secondaryTxt),
                              ),
                              value: _overlayEnabled && _hasOverlayPerm,
                              activeColor: accentEmerald,
                              onChanged: _toggleOverlay,
                            ),
                            if (!_hasOverlayPerm) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: Icon(Icons.open_in_new, size: 16, color: accentEmerald),
                                  label: Text(
                                    tr('منح إذن الظهور فوق التطبيقات', 'Grant Display Over Apps Permission'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: accentEmerald,
                                    ),
                                  ),
                                  onPressed: () => _notif.requestOverlayPermission(),
                                ),
                              ),
                            ],
                            const Divider(height: 18),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(Icons.vibration, color: primaryTxt),
                              title: Text(
                                tr('الاهتزاز مع الأذان', 'Vibrate with Azan'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: primaryTxt,
                                ),
                              ),
                              value: _vibrate,
                              activeColor: accentEmerald,
                              onChanged: (val) async {
                                await _notif.setAzanOverlayVibrate(val);
                                if (mounted) setState(() => _vibrate = val);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2. Islamic Wall Backgrounds Picker
                      Text(
                        tr('خلفيات شاشة الأذان', 'Azan Wall Backgrounds'),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryTxt,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 174,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AzanAudioService.wallpapers.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, idx) {
                            final wall = AzanAudioService.wallpapers[idx];
                            final selected = _wallpaperKey == wall.key;
                            return GestureDetector(
                              onTap: () async {
                                await _notif.setAzanWallpaperKey(wall.key);
                                if (mounted) setState(() => _wallpaperKey = wall.key);
                              },
                              child: SizedBox(
                                width: 106,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: selected
                                                ? accentEmerald
                                                : AppConstants.borderColor(context),
                                            width: selected ? 2.5 : 1,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.asset(wall.assetPath, fit: BoxFit.cover),
                                            if (selected)
                                              Positioned(
                                                top: 6,
                                                left: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: accentEmerald,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      wall.localizedTitle(isAr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                        color: selected ? accentEmerald : secondaryTxt,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Azan Sounds & Muezzins
                      Text(
                        tr('أصوات الأذان والمؤذنين', 'Azan Voices & Sounds'),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryTxt,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.cardSurface(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppConstants.borderColor(context)),
                        ),
                        child: ValueListenableBuilder<String?>(
                          valueListenable: _audio.currentTrack,
                          builder: (context, playingTrack, _) {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: AzanAudioService.tracks.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: AppConstants.borderColor(context),
                              ),
                              itemBuilder: (_, idx) {
                                final track = AzanAudioService.tracks[idx];
                                final selected = _soundMode == track.key;
                                final isPlayingThis = playingTrack == track.key;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  leading: Icon(
                                    track.isSilent
                                        ? Icons.volume_off_outlined
                                        : (track.isDefaultTone
                                            ? Icons.notifications_none
                                            : Icons.volume_up_outlined),
                                    color: selected ? accentEmerald : secondaryTxt,
                                  ),
                                  title: Text(
                                    track.localizedTitle(isAr),
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13,
                                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                      color: primaryTxt,
                                    ),
                                  ),
                                  subtitle: Text(
                                    track.localizedSubtitle(isAr),
                                    style: TextStyle(fontSize: 11, color: secondaryTxt),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (selected)
                                        Icon(Icons.check, color: accentEmerald, size: 20),
                                      if (!track.isSilent) ...[
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: Icon(
                                            isPlayingThis
                                                ? Icons.stop_circle
                                                : Icons.play_circle_fill,
                                            color: isPlayingThis ? Colors.redAccent : accentEmerald,
                                          ),
                                          onPressed: () => _audio.playSoundKey(track.key),
                                        ),
                                      ],
                                    ],
                                  ),
                                  onTap: () async {
                                    await _notif.setPrayerSoundMode(track.key);
                                    if (mounted) setState(() => _soundMode = track.key);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky Preview Bottom Button
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: AppConstants.cardSurface(context),
                      border: Border(
                        top: BorderSide(color: AppConstants.borderColor(context)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentEmerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.fullscreen),
                        label: Text(
                          tr('معاينة شاشة الأذان الآن', 'Preview Azan Screen'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => _notif.previewAzanOverlay(cityName: _cityName),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
