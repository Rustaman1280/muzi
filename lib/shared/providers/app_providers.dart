import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/audio_player_service.dart'; // legacy simple service (optional)
import '../../core/services/audio_player_handler.dart';
import '../../core/controllers/audio_controller.dart';
import '../../core/services/permission_service.dart';
import '../../core/models/song.dart';
import '../../features/home/home_screen.dart';
import '../../features/download/download_screen.dart';
import '../../features/download/tiktok/tiktok_downloader.dart';
import '../../features/player/player_screen.dart';
import '../../core/database/hive_service.dart';
import '../../core/models/library_models.dart';
import '../widgets/main_scaffold.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/download',
            name: 'download',
            builder: (context, state) => const DownloadScreen(),
          ),
          GoRoute(
            path: '/player',
            name: 'player',
            pageBuilder: (context, state) {
              // Expecting extra map with current song info
              final extra = state.extra as Map<String, dynamic>?;
              final title = extra?['title'] as String? ?? 'Unknown';
              final artist = extra?['artist'] as String? ?? 'Unknown';
              final art = extra?['artwork'] as ImageProvider<Object>? ?? const AssetImage('assets/images/foto (1).jpg');
              final duration = extra?['duration'] as Duration? ?? Duration.zero;
              final position = extra?['position'] as Duration? ?? Duration.zero;
              final playing = extra?['playing'] as bool? ?? false;
              return CustomTransitionPage(
                key: state.pageKey,
                transitionDuration: const Duration(milliseconds: 500),
                child: PlayerScreen(
                  title: title,
                  artist: artist,
                  artwork: art,
                  duration: duration,
                  position: position,
                  isPlaying: playing,
                ),
                transitionsBuilder: (context, animation, secondary, child) {
                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(curved), child: child),
                  );
                },
              );
            },
          ),
        ],
      ),
    ],
  );
});

// Advanced audio handler & controller
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  return AudioPlayerHandler();
});

final audioControllerProvider =
    StateNotifierProvider<AudioController, AudioControllerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return AudioController(handler);
});

// Library Repository Provider
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});

// Download Queue Provider
final downloadQueueProvider = StateNotifierProvider<DownloadQueueController, DownloadQueueState>((ref) {
  return DownloadQueueController();
});

// Audio Player Service Provider
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

// Current Song Provider
final currentSongProvider = StateProvider<Song?>((ref) => null);

// Player State Providers
final isPlayingProvider = StateProvider<bool>((ref) => false);
final currentPositionProvider = StateProvider<Duration>((ref) => Duration.zero);
final totalDurationProvider = StateProvider<Duration?>((ref) => null);

// Volume Provider
final volumeProvider = StateProvider<double>((ref) => 1.0);

// Shuffle and Repeat Providers
final shuffleModeProvider = StateProvider<bool>((ref) => false);
final repeatModeProvider = StateProvider<bool>((ref) => false);

// Permissions Provider
final permissionsProvider = FutureProvider<Map<String, bool>>((ref) async {
  return await PermissionService.requestAllPermissions();
});

// Song List Provider (for library)
final songListProvider = StateProvider<List<Song>>((ref) => []);

// Current Playlist Provider
final currentPlaylistProvider = StateProvider<List<Song>>((ref) => []);

// Current Index in Playlist
final currentIndexProvider = StateProvider<int>((ref) => 0);

// (Removed legacy inline AudioState/Controller in favor of advanced handler)

// Library Repository
class LibraryRepository {
  Future<List<Song>> getAllSongs() async {
    // TODO: Implement actual music scanning
    return [];
  }

  Future<List<Song>> searchSongs(String query) async {
    // TODO: Implement search
    return [];
  }
}

// Download Queue State
class DownloadQueueState {
  final List<DownloadItem> queue;
  final List<DownloadItem> completed;
  final List<DownloadItem> failed;

  const DownloadQueueState({
    this.queue = const [],
    this.completed = const [],
    this.failed = const [],
  });

  DownloadQueueState copyWith({
    List<DownloadItem>? queue,
    List<DownloadItem>? completed,
    List<DownloadItem>? failed,
  }) {
    return DownloadQueueState(
      queue: queue ?? this.queue,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
    );
  }
}

// Download Item
class DownloadItem {
  final String id;
  final String title;
  final String url;
  final double progress;
  final DownloadStatus status;
  final String? source; // e.g. TikTok
  final String? filePath; // local path when downloaded
  final int? sizeBytes;
  final String? error;

  const DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    this.source,
    this.filePath,
    this.sizeBytes,
    this.error,
  });

  DownloadItem copyWith({
    String? id,
    String? title,
    String? url,
    double? progress,
    DownloadStatus? status,
    String? source,
    String? filePath,
    int? sizeBytes,
    String? error,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      source: source ?? this.source,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      error: error ?? this.error,
    );
  }
}

enum DownloadStatus { pending, downloading, completed, failed, paused }

// Download Queue Controller
class DownloadQueueController extends StateNotifier<DownloadQueueState> {
  DownloadQueueController() : super(const DownloadQueueState());

  void addToQueue(DownloadItem item) {
    state = state.copyWith(
      queue: [...state.queue, item],
    );
  }

  void updateProgress(String id, double progress) {
    final updatedQueue = state.queue.map((item) {
      if (item.id == id) {
        return item.copyWith(progress: progress);
      }
      return item;
    }).toList();

    state = state.copyWith(queue: updatedQueue);
  }

  void markCompleted(String id) {
    final item = state.queue.firstWhere((item) => item.id == id);
    final completedItem = item.copyWith(status: DownloadStatus.completed);
    
    state = state.copyWith(
      queue: state.queue.where((item) => item.id != id).toList(),
      completed: [...state.completed, completedItem],
    );
  }

  void markFailed(String id) {
    final item = state.queue.firstWhere((item) => item.id == id);
    final failedItem = item.copyWith(status: DownloadStatus.failed);
    
    state = state.copyWith(
      queue: state.queue.where((item) => item.id != id).toList(),
      failed: [...state.failed, failedItem],
    );
  }

  // TikTok download flow with progress updates
  Future<void> startTikTokDownload(String url, {String? customTitle}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final initial = DownloadItem(
      id: id,
      title: customTitle ?? 'TikTok Audio',
      url: url,
      progress: 0,
      status: DownloadStatus.downloading,
      source: 'TikTok',
    );
    addToQueue(initial);
    final downloader = TikTokDownloader();
    try {
      final result = await downloader.fetchAudio(url, onProgress: (recv, total) {
        double prog;
        if (total == null || total == 0) {
          prog = (recv % 1000000) / 1000000; // pseudo cycle to show movement
        } else {
          prog = (recv / total) * 100;
        }
        updateProgress(id, prog.clamp(0, 100));
      });
      // mark complete and move to completed
      updateProgress(id, 100);
      final idx = state.queue.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final item = state.queue[idx];
        final finalTitle = customTitle ?? result.title;
        final updated = item.copyWith(status: DownloadStatus.completed, filePath: result.file.path, sizeBytes: result.size, title: finalTitle);
        state = state.copyWith(
          queue: state.queue.where((e) => e.id != id).toList(),
          completed: [...state.completed, updated],
        );
        // Persist to library (simple Track entry) so it shows on Home
        try {
          final track = Track(
            id: 'dl_$id',
            title: finalTitle,
            artist: 'TikTok',
            album: 'Downloads',
            durationMs: 0, // unknown without decoding; can update later
            path: result.file.path,
            addedAt: DateTime.now().millisecondsSinceEpoch,
            artworkPath: null,
            genre: null,
          );
            HiveService.trackBox.add(track);
        } catch (_) {}
      }
    } catch (e) {
      // move to failed
      final idx = state.queue.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final item = state.queue[idx];
        final failed = item.copyWith(status: DownloadStatus.failed, error: e.toString());
        state = state.copyWith(
          queue: state.queue.where((e) => e.id != id).toList(),
          failed: [...state.failed, failed],
        );
      }
    }
  }
}
