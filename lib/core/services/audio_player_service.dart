import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;

  AudioPlayer get player => _audioPlayer;
  Song? get currentSong => _currentSong;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<void> playSong(Song song) async {
    try {
      _currentSong = song;
      await _audioPlayer.setFilePath(song.filePath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
