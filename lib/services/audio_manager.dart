import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  final AudioPlayer _musicPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  String _currentTrack = '';

  Future<void> playMusic(String trackName) async {
    if (_currentTrack == trackName) return;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource('music/$trackName'));
      _currentTrack = trackName;
    } catch (e) {
      print("Erro ao tocar música: $e");
    }
  }

  void pauseMusic() => _musicPlayer.pause();
  void stopMusic() => _musicPlayer.stop();
  void dispose() => _musicPlayer.dispose();
  void resumeMusic() => _musicPlayer.resume();
}