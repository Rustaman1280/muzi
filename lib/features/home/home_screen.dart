import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/models/song.dart';
import '../../core/repository/library_repository.dart' as librepo;
import '../../core/models/library_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final audio = ref.read(audioControllerProvider.notifier);
  final repo = ref.read(librepo.libraryRepositoryProvider);

  // Gunakan FutureBuilder sederhana untuk memuat track dari Hive.
  return FutureBuilder<List<Track>>(
    future: repo.getAllTracks(),
    builder: (context, snap) {
      final tracks = snap.data ?? [];
      return Scaffold(
        appBar: AppBar(
          title: const Text('Muziek'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                // Jalankan scan ulang dan rebuild UI
                await repo.refreshLibrary();
                // ignore: use_build_context_synchronously
                (context as Element).markNeedsBuild();
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: tracks.isEmpty
            ? _EmptyLibrary(onScan: () async {
                try {
                  await repo.refreshLibrary();
                  // ignore: use_build_context_synchronously
                  (context as Element).markNeedsBuild();
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scan gagal: $e')),
                  );
                }
              })
            : _TrackList(
                tracks: tracks,
                onPlay: (startIndex) {
                  final songs = tracks.map(_trackToSong).toList();
                  audio.loadAndPlay(songs, startIndex: startIndex);
                },
              ),
      );
    },
  );
  }

  // (Card cepat dihapus karena tidak digunakan lagi)

  Song _trackToSong(Track t) => Song(
        id: t.id,
        title: t.title,
        artist: t.artist,
        album: t.album,
        filePath: t.path,
        duration: Duration(milliseconds: t.durationMs),
        albumArt: t.artworkPath,
      );
}

class _EmptyLibrary extends StatelessWidget {
  final Future<void> Function() onScan;
  const _EmptyLibrary({required this.onScan});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music, size: 64),
            const SizedBox(height: 16),
            const Text('Belum ada lagu. Mulai scan untuk memuat musik lokal.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Musik'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  final List<Track> tracks;
  final void Function(int index) onPlay;
  const _TrackList({required this.tracks, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = tracks[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
            title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => onPlay(index),
          trailing: const Icon(Icons.play_arrow),
        );
      },
    );
  }
}
