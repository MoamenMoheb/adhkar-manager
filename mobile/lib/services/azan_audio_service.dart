import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AzanTrack {
  final String key;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final bool isSilent;
  final bool isDefaultTone;

  const AzanTrack({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    this.isSilent = false,
    this.isDefaultTone = false,
  });

  String localizedTitle(bool isAr) => isAr ? titleAr : titleEn;
  String localizedSubtitle(bool isAr) => isAr ? subtitleAr : subtitleEn;
}

class AzanWallpaper {
  final String key;
  final String titleAr;
  final String titleEn;
  final String assetPath;

  const AzanWallpaper({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.assetPath,
  });

  String localizedTitle(bool isAr) => isAr ? titleAr : titleEn;
}

class AzanAudioService {
  static final AzanAudioService instance = AzanAudioService._internal();
  static const MethodChannel _playerChannel =
      MethodChannel('com.moamenmoheb.adhkar_sanctuary/azan_player');

  static const List<AzanTrack> tracks = [
    AzanTrack(
      key: 'silent',
      titleAr: 'صامت (بدون صوت)',
      titleEn: 'Silent (No Sound)',
      subtitleAr: 'إشعار مرئي بدون صوت',
      subtitleEn: 'Visual notification without audio',
      isSilent: true,
    ),
    AzanTrack(
      key: 'default',
      titleAr: 'نغمة الإشعارات الافتراضية',
      titleEn: 'System Default Tone',
      subtitleAr: 'نغمة التنبيه المعتادة في الهاتف',
      subtitleEn: 'Standard device notification ringtone',
      isDefaultTone: true,
    ),
    AzanTrack(
      key: 'takbeer',
      titleAr: 'تكبيرة الأذان المختصرة',
      titleEn: 'Short Takbeer (10s)',
      subtitleAr: 'تكبير مختصر (١٠ ثوانٍ)',
      subtitleEn: 'Brief Takbeer call (10 seconds)',
    ),
    AzanTrack(
      key: 'azan',
      titleAr: 'أذان الحرم المكي',
      titleEn: 'Makkah Haram Azan',
      subtitleAr: 'مكة المكرمة (الافتراضي)',
      subtitleEn: 'Makkah Al-Mukarramah (Default)',
    ),
    AzanTrack(
      key: 'azan_makkah_mulla',
      titleAr: 'الشيخ علي بن أحمد ملا',
      titleEn: 'Sheikh Ali Ahmed Mulla',
      subtitleAr: 'الحرم المكي — مكة المكرمة',
      subtitleEn: 'Grand Mosque — Makkah',
    ),
    AzanTrack(
      key: 'azan_madinah',
      titleAr: 'أذان المسجد النبوي',
      titleEn: 'Madinah Mosque Azan',
      subtitleAr: 'المدينة المنورة',
      subtitleEn: "Prophet's Mosque — Madinah",
    ),
    AzanTrack(
      key: 'azan_fajr_makkah',
      titleAr: 'أذان الفجر — الحرم المكي',
      titleEn: 'Fajr Azan — Makkah',
      subtitleAr: 'مكة المكرمة (الصلاة خير من النوم)',
      subtitleEn: 'Makkah (As-Salatu Khayrun Minan-Nawm)',
    ),
    AzanTrack(
      key: 'azan_fajr_madinah',
      titleAr: 'أذان الفجر — المسجد النبوي',
      titleEn: 'Fajr Azan — Madinah',
      subtitleAr: 'المدينة المنورة',
      subtitleEn: "Madinah Prophet's Mosque",
    ),
    AzanTrack(
      key: 'azan_aqsa',
      titleAr: 'أذان المسجد الأقصى',
      titleEn: 'Al-Aqsa Mosque Azan',
      subtitleAr: 'القدس الشريف — فلسطين',
      subtitleEn: 'Al-Quds — Palestine',
    ),
    AzanTrack(
      key: 'azan_abdulbasit',
      titleAr: 'الشيخ عبد الباسط عبد الصمد',
      titleEn: 'Sheikh Abdul Basit Abdus Samad',
      subtitleAr: 'تلاوة مصرية أصيلة',
      subtitleEn: 'Classic Egyptian Recitation',
    ),
    AzanTrack(
      key: 'azan_refaat',
      titleAr: 'الشيخ محمد رفعت',
      titleEn: 'Sheikh Muhammad Rifat',
      subtitleAr: 'القاهرة — مصر',
      subtitleEn: 'Cairo — Egypt',
    ),
    AzanTrack(
      key: 'azan_toubar',
      titleAr: 'الشيخ نصر الدين طوبار (الفجر)',
      titleEn: 'Sheikh Nasr El-Din Tobar (Fajr)',
      subtitleAr: 'مصر — أذان الفجر',
      subtitleEn: 'Egypt — Fajr Call',
    ),
    AzanTrack(
      key: 'azan_afasy',
      titleAr: 'الشيخ مشاري راشد العفاسي',
      titleEn: 'Sheikh Mishary Rashid Alafasy',
      subtitleAr: 'دولة الكويت',
      subtitleEn: 'Kuwait',
    ),
    AzanTrack(
      key: 'azan_qatami',
      titleAr: 'الشيخ ناصر القطامي',
      titleEn: 'Sheikh Nasser Al-Qatami',
      subtitleAr: 'المملكة العربية السعودية',
      subtitleEn: 'Saudi Arabia',
    ),
    AzanTrack(
      key: 'azan_dosari',
      titleAr: 'الشيخ ياسر الدوسري',
      titleEn: 'Sheikh Yasser Al-Dosari',
      subtitleAr: 'الحرم المكي — السعودية',
      subtitleEn: 'Makkah — Saudi Arabia',
    ),
  ];

  static const List<AzanWallpaper> wallpapers = [
    AzanWallpaper(
      key: 'wall_makkah',
      titleAr: 'الحرم المكي',
      titleEn: 'Makkah Courtyard',
      assetPath: 'assets/wallpapers/wall_makkah.jpg',
    ),
    AzanWallpaper(
      key: 'wall_interior',
      titleAr: 'رحاب المسجد',
      titleEn: 'Prayer Hall',
      assetPath: 'assets/wallpapers/wall_interior.jpg',
    ),
    AzanWallpaper(
      key: 'wall_madinah',
      titleAr: 'القبة الخضراء',
      titleEn: 'Green Dome',
      assetPath: 'assets/wallpapers/wall_madinah.jpg',
    ),
    AzanWallpaper(
      key: 'wall_cairo',
      titleAr: 'مساجد القاهرة',
      titleEn: 'Historic Cairo',
      assetPath: 'assets/wallpapers/wall_cairo.jpg',
    ),
  ];

  static AzanTrack findTrack(String key) {
    for (final t in tracks) {
      if (t.key == key) return t;
    }
    return tracks.firstWhere((t) => t.key == 'azan');
  }

  static AzanWallpaper findWallpaper(String key) {
    for (final w in wallpapers) {
      if (w.key == key) return w;
    }
    return wallpapers.first;
  }

  AzanAudioService._internal() {
    _player.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      currentTrack.value = null;
    });
    _playerChannel.setMethodCallHandler((call) async {
      if (call.method == 'onCompleted') {
        isPlaying.value = false;
        currentTrack.value = null;
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentTrack = ValueNotifier<String?>(null);

  Future<void> playSoundKey(String soundKey) async {
    if (soundKey == 'silent') {
      await stop();
      return;
    }
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      try {
        if (isPlaying.value && currentTrack.value == soundKey) {
          await stop();
          return;
        }
        final started = await _playerChannel.invokeMethod<bool>('play', {
          'soundKey': soundKey,
        });
        if (started == true) {
          currentTrack.value = soundKey;
          isPlaying.value = true;
        } else {
          currentTrack.value = null;
          isPlaying.value = false;
        }
        return;
      } catch (e) {
        debugPrint('Native azan preview notice: $e');
      }
    }
    await playAzan(shortTakbeer: soundKey == 'takbeer');
  }

  Future<void> playAzan({bool shortTakbeer = false}) async {
    final track = shortTakbeer ? 'takbeer' : 'azan';
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      await playSoundKey(track);
      return;
    }
    try {
      if (isPlaying.value && currentTrack.value == track) {
        await stop();
        return;
      }
      await _player.stop();
      await _player.play(AssetSource(shortTakbeer ? 'audio/takbeer.mp3' : 'audio/azan.mp3'));
      currentTrack.value = track;
      isPlaying.value = true;
    } catch (e) {
      debugPrint('Error playing Azan audio: $e');
      isPlaying.value = false;
      currentTrack.value = null;
    }
  }

  Future<void> stop() async {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      try {
        await _playerChannel.invokeMethod('stop');
      } catch (_) {}
    }
    try {
      await _player.stop();
    } catch (_) {}
    isPlaying.value = false;
    currentTrack.value = null;
  }
}
