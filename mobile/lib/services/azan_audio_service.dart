import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AzanAudioService {
  static final AzanAudioService instance = AzanAudioService._internal();
  AzanAudioService._internal() {
    _player.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      currentTrack.value = null;
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentTrack = ValueNotifier<String?>(null);

  Future<void> playAzan({bool shortTakbeer = false}) async {
    try {
      final track = shortTakbeer ? 'takbeer' : 'azan';
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
    try {
      await _player.stop();
    } catch (_) {}
    isPlaying.value = false;
    currentTrack.value = null;
  }
}
