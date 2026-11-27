import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AzanTrack {
  final String key;
  final String titleAr;
  final String subtitleAr;
  final bool isSilent;
  final bool isDefaultTone;

  const AzanTrack({
    required this.key,
    required this.titleAr,
    required this.subtitleAr,
    this.isSilent = false,
    this.isDefaultTone = false,
  });
}

class AzanWallpaper {
  final String key;
  final String titleAr;
  final String assetPath;

  const AzanWallpaper({
    required this.key,
    required this.titleAr,
    required this.assetPath,
  });
}

class AzanAudioService {
  static final AzanAudioService instance = AzanAudioService._internal();
  static const MethodChannel _playerChannel =
      MethodChannel('com.moamenmoheb.adhkar_sanctuary/azan_player');

  static const List<AzanTrack> tracks = [
    AzanTrack(
      key: 'silent',
      titleAr: 'صامت (بدون صوت)',
      subtitleAr: 'إشعار مرئي بدون صوت',
      isSilent: true,
    ),
    AzanTrack(
      key: 'default',
      titleAr: 'نغمة الإشعارات الافتراضية',
      subtitleAr: 'نغمة التنبيه المعتادة في الهاتف',
      isDefaultTone: true,
    ),
    AzanTrack(
      key: 'takbeer',
      titleAr: 'تكبيرة الأذان المختصرة',
      subtitleAr: 'تكبير مختصر (١٠ ثوانٍ)',
    ),
    AzanTrack(
      key: 'azan',
      titleAr: 'أذان الحرم المكي',
      subtitleAr: 'مكة المكرمة (الافتراضي)',
    ),
    AzanTrack(
      key: 'azan_makkah_mulla',
      titleAr: 'الشيخ علي بن أحمد ملا',
      subtitleAr: 'الحرم المكي — مكة المكرمة',
    ),
    AzanTrack(
      key: 'azan_madinah',
      titleAr: 'أذان المسجد النبوي',
      subtitleAr: 'المدينة المنورة',
    ),
    AzanTrack(
      key: 'azan_fajr_makkah',
      titleAr: 'أذان الفجر — الحرم المكي',
      subtitleAr: 'مكة المكرمة (الصلاة خير من النوم)',
    ),
    AzanTrack(
      key: 'azan_fajr_madinah',
      titleAr: 'أذان الفجر — المسجد النبوي',
      subtitleAr: 'المدينة المنورة',
    ),
    AzanTrack(
      key: 'azan_aqsa',
      titleAr: 'أذان المسجد الأقصى',
      subtitleAr: 'القدس الشريف — فلسطين',
    ),
    AzanTrack(
      key: 'azan_abdulbasit',
      titleAr: 'الشيخ عبد الباسط عبد الصمد',
      subtitleAr: 'تلاوة مصرية أصيلة',
    ),
    AzanTrack(
      key: 'azan_refaat',
      titleAr: 'الشيخ محمد رفعت',
      subtitleAr: 'القاهرة — مصر',
    ),
    AzanTrack(
      key: 'azan_toubar',
      titleAr: 'الشيخ نصر الدين طوبار (الفجر)',
      subtitleAr: 'مصر — أذان الفجر',
    ),
    AzanTrack(
      key: 'azan_afasy',
      titleAr: 'الشيخ مشاري راشد العفاسي',
      subtitleAr: 'دولة الكويت',
    ),
    AzanTrack(
      key: 'azan_qatami',
      titleAr: 'الشيخ ناصر القطامي',
      subtitleAr: 'المملكة العربية السعودية',
    ),
    AzanTrack(
      key: 'azan_dosari',
      titleAr: 'الشيخ ياسر الدوسري',
      subtitleAr: 'الحرم المكي — السعودية',
    ),
  ];

  static const List<AzanWallpaper> wallpapers = [
    AzanWallpaper(
      key: 'wall_makkah',
      titleAr: 'الحرم المكي',
      assetPath: 'assets/wallpapers/wall_makkah.jpg',
    ),
    AzanWallpaper(
      key: 'wall_interior',
      titleAr: 'رحاب المسجد',
      assetPath: 'assets/wallpapers/wall_interior.jpg',
    ),
    AzanWallpaper(
      key: 'wall_madinah',
      titleAr: 'القبة الخضراء',
      assetPath: 'assets/wallpapers/wall_madinah.jpg',
    ),
    AzanWallpaper(
      key: 'wall_cairo',
      titleAr: 'مساجد القاهرة',
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
