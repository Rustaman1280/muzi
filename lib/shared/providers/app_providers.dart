import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/audio_player_service.dart'; // legacy simple service (optional)
import '../../core/services/audio_player_handler.dart';
import '../../core/controllers/audio_controller.dart';
import '../../core/services/permission_service.dart';
import '../../core/models/song.dart';
import '../../features/home/home_screen.dart';
import '../../features/download/download_screen.dart';
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

  const DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
  });

  DownloadItem copyWith({
    String? id,
    String? title,
    String? url,
    double? progress,
    DownloadStatus? status,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      progress: progress ?? this.progress,
      status: status ?? this.status,
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
}
