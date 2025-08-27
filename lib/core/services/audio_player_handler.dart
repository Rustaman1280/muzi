import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';

// Utility extension for converting between Song and MediaItem
extension SongMediaItemX on Song {
	MediaItem toMediaItem() => MediaItem(
				id: id,
				title: title,
				artist: artist,
				album: album,
				artUri: albumArt != null ? Uri.parse(albumArt!) : null,
				duration: duration,
				extras: toExtras(),
			);
}

Song songFromMediaItem(MediaItem item) => Song(
			id: item.id,
			title: item.title,
			artist: item.artist ?? 'Unknown',
			album: item.album ?? 'Unknown',
			albumArt: item.artUri?.toString(),
			filePath: item.extras?['filePath'] ?? '',
			duration: item.duration ?? Duration.zero,
			trackNumber: item.extras?['trackNumber'],
			genre: item.extras?['genre'],
		);

class AudioPlayerHandler extends BaseAudioHandler
		with QueueHandler, SeekHandler {
	final _player = AudioPlayer();

	// Subjects for custom combined streams
	final _currentSongSubject = BehaviorSubject<Song?>.seeded(null);
	final _positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

	Stream<Song?> get currentSongStream => _currentSongSubject.stream;
	Stream<Duration> get positionStream => _positionSubject.stream;

	// Combined playback state (position + buffered + total)
		Stream<PlaybackState> get playbackStateCombined => Rx.combineLatest3<
						Duration,
						Duration,
						PlayerState,
						PlaybackState>(_player.positionStream, _player.bufferedPositionStream,
				_player.playerStateStream, (pos, buff, state) {
			final base = playbackState.valueOrNull ?? PlaybackState();
			return base.copyWith(
				updatePosition: pos,
				bufferedPosition: buff,
				playing: state.playing,
				processingState: _transformProcessingState(state.processingState),
			);
		});

	AudioPlayerHandler() {
		_init();
	}

	Future<void> _init() async {
		// Forward position
		_player.positionStream.listen(_positionSubject.add);
		// Listen for current index changes to update current song
		_player.currentIndexStream.listen((index) {
			if (index == null || queue.value.isEmpty) return;
			final item = queue.value[index];
			_currentSongSubject.add(songFromMediaItem(item));
			mediaItem.add(item);
		});

		// Propagate play/pause/processing state
			_player.playerStateStream.listen((playerState) {
				final playing = playerState.playing;
				final processing = _transformProcessingState(playerState.processingState);
				final base = playbackState.valueOrNull ?? PlaybackState();
				playbackState.add(base.copyWith(
						playing: playing,
						processingState: processing,
						controls: [
							MediaControl.skipToPrevious,
							if (playing) MediaControl.pause else MediaControl.play,
							MediaControl.stop,
							MediaControl.skipToNext,
						],
						systemActions: const {
							MediaAction.seek,
							MediaAction.seekForward,
							MediaAction.seekBackward,
							MediaAction.setShuffleMode,
							MediaAction.setRepeatMode,
						}));
			});
	}

	AudioProcessingState _transformProcessingState(ProcessingState s) {
		return switch (s) {
			ProcessingState.idle => AudioProcessingState.idle,
			ProcessingState.loading => AudioProcessingState.loading,
			ProcessingState.buffering => AudioProcessingState.buffering,
			ProcessingState.ready => AudioProcessingState.ready,
			ProcessingState.completed => AudioProcessingState.completed,
		};
	}

	// Queue / loading
	Future<void> loadQueue(List<Song> songs, {int startIndex = 0}) async {
		final items = songs.map((e) => e.toMediaItem()).toList();
		queue.add(items);
		try {
			await _player.setAudioSource(ConcatenatingAudioSource(
					children: items
							.map((m) => m.extras?['filePath'] != null
									? AudioSource.uri(Uri.parse(m.extras!['filePath']))
									: AudioSource.uri(Uri.parse(m.id)))
							.toList()));
			if (startIndex > 0 && startIndex < items.length) {
				await _player.seek(Duration.zero, index: startIndex);
			}
			await play();
		} catch (e, _) {
			// Revert queue on failure to avoid stuck UI
			queue.add([]);
			final base = playbackState.valueOrNull ?? PlaybackState();
			playbackState.add(base.copyWith(
				playing: false,
				processingState: AudioProcessingState.idle,
				androidCompactActionIndices: const []));
		}
	}

	Future<void> addSong(Song song) async {
		final items = [...queue.value, song.toMediaItem()];
		queue.add(items);
	}

	// Playback controls
	@override
	Future<void> play() => _player.play();

	@override
	Future<void> pause() => _player.pause();

	@override
	Future<void> stop() async {
		await _player.stop();
		await super.stop();
	}

	@override
	Future<void> seek(Duration position) => _player.seek(position);

	@override
	Future<void> skipToNext() => _player.seekToNext();

	@override
	Future<void> skipToPrevious() => _player.seekToPrevious();

	Future<void> setRepeat(AudioServiceRepeatMode mode) async {
		switch (mode) {
			case AudioServiceRepeatMode.one:
				await _player.setLoopMode(LoopMode.one);
				break;
			case AudioServiceRepeatMode.all:
				await _player.setLoopMode(LoopMode.all);
				break;
			default:
				await _player.setLoopMode(LoopMode.off);
		}
		final base = playbackState.valueOrNull ?? PlaybackState();
		playbackState.add(base.copyWith(repeatMode: mode));
	}

	Future<void> toggleShuffle() async {
		final enabled = _player.shuffleModeEnabled;
		if (!enabled) {
			await _player.shuffle();
		}
		await _player.setShuffleModeEnabled(!enabled);
		final base = playbackState.valueOrNull ?? PlaybackState();
		playbackState.add(base.copyWith(
			shuffleMode: !enabled
				? AudioServiceShuffleMode.all
				: AudioServiceShuffleMode.none));
	}

	// Load and play single local file (e.g. m4a) or remote URI.
	// Automatically distinguishes local paths and builds proper file URI.
	Future<void> playPath(String pathOrUri, {String? title}) async {
		try {
			final isRemote = pathOrUri.startsWith('http://') || pathOrUri.startsWith('https://');
			final uri = isRemote ? Uri.parse(pathOrUri) : Uri.file(pathOrUri);
			await _player.setAudioSource(AudioSource.uri(uri));
			// Provide a minimal mediaItem so lockscreen / notif can show something when playing ad-hoc file
			mediaItem.add(MediaItem(
				id: uri.toString(),
				title: title ?? (isRemote ? uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Stream' : uri.path.split('/').last),
				artist: 'Local',
				duration: _player.duration,
				extras: {'filePath': pathOrUri},
			));
			await play();
		} catch (e, _) {
			final base = playbackState.valueOrNull ?? PlaybackState();
			playbackState.add(base.copyWith(
				playing: false,
				processingState: AudioProcessingState.idle));
		}
	}

	@override
	Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
		final enable = shuffleMode == AudioServiceShuffleMode.all;
		if (enable && !_player.shuffleModeEnabled) {
			await _player.shuffle();
		}
		await _player.setShuffleModeEnabled(enable);
		final base = playbackState.valueOrNull ?? PlaybackState();
		playbackState.add(base.copyWith(shuffleMode: shuffleMode));
	}

	@override
	Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
		await setRepeat(repeatMode);
	}

		Future<void> disposeHandler() async {
			await _player.dispose();
			await _currentSongSubject.close();
			await _positionSubject.close();
		}
}
