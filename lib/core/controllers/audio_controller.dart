import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/song.dart';
import '../services/audio_player_handler.dart';

class AudioControllerState {
  final Song? current;
  final List<Song> queue;
  final bool playing;
  final Duration position;
  final Duration buffered;
  final Duration? duration;
  final AudioServiceRepeatMode repeatMode;
  final AudioServiceShuffleMode shuffleMode;

  const AudioControllerState({
    this.current,
    this.queue = const [],
    this.playing = false,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration,
    this.repeatMode = AudioServiceRepeatMode.none,
    this.shuffleMode = AudioServiceShuffleMode.none,
  });

  AudioControllerState copyWith({
    Song? current,
    List<Song>? queue,
    bool? playing,
    Duration? position,
    Duration? buffered,
    Duration? duration,
    AudioServiceRepeatMode? repeatMode,
    AudioServiceShuffleMode? shuffleMode,
  }) => AudioControllerState(
        current: current ?? this.current,
        queue: queue ?? this.queue,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        buffered: buffered ?? this.buffered,
        duration: duration ?? this.duration,
        repeatMode: repeatMode ?? this.repeatMode,
        shuffleMode: shuffleMode ?? this.shuffleMode,
      );
}

class AudioController extends StateNotifier<AudioControllerState> {
  final AudioPlayerHandler handler;
  late final StreamSubscription _songSub;
  late final StreamSubscription _queueSub;
  late final StreamSubscription _playbackCombinedSub;

  AudioController(this.handler) : super(const AudioControllerState()) {
    _songSub = handler.currentSongStream.listen((song) {
      state = state.copyWith(current: song, duration: song?.duration);
    });
    _queueSub = handler.queue.listen((items) {
      state = state.copyWith(queue: items.map(songFromMediaItem).toList());
    });
    _playbackCombinedSub = handler.playbackStateCombined.listen((ps) {
      state = state.copyWith(
        playing: ps.playing,
        position: ps.updatePosition,
        buffered: ps.bufferedPosition,
        repeatMode: ps.repeatMode,
        shuffleMode: ps.shuffleMode,
      );
    });
  }

  // API
  Future<void> loadAndPlay(List<Song> songs, {int startIndex = 0}) =>
      handler.loadQueue(songs, startIndex: startIndex);
  Future<void> add(Song song) => handler.addSong(song);
  Future<void> play() => handler.play();
  Future<void> pause() => handler.pause();
  Future<void> stop() => handler.stop();
  Future<void> seek(Duration d) => handler.seek(d);
  Future<void> next() => handler.skipToNext();
  Future<void> previous() => handler.skipToPrevious();
  Future<void> toggleShuffle() => handler.toggleShuffle();
  Future<void> setRepeat(AudioServiceRepeatMode m) => handler.setRepeat(m);
  Future<void> playPath(String p) => handler.playPath(p);

  Stream<Duration> get positionStream => handler.positionStream;
  Stream<Song?> get currentTrackStream => handler.currentSongStream;
  Stream<List<Song>> get queueStream => handler.queue.map((q) => q.map(songFromMediaItem).toList());
  Stream<PlaybackState> get playbackStateStream => handler.playbackStateCombined;

  @override
  void dispose() {
    _songSub.cancel();
    _queueSub.cancel();
    _playbackCombinedSub.cancel();
    handler.disposeHandler();
    super.dispose();
  }
}