import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }

  static Future<void> playAction() async {
    try {
      await _player.play(AssetSource('sounds/action.mp3'));
    } catch (e) {
      print('Error playing action sound: $e');
    }
  }
}
