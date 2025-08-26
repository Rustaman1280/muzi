import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:collection/collection.dart';
import '../database/hive_service.dart';
import '../models/library_models.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});

class LibraryRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> ensurePermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_AUDIO; below uses READ_EXTERNAL_STORAGE
      final androidInfo = await Permission.storage.status; // fallback
      final audioPerm = await Permission.audio.status;
      if (audioPerm.isGranted || androidInfo.isGranted) return true;
      final req = await [Permission.audio, Permission.storage].request();
      return req.values.any((s) => s.isGranted);
    }
    return true; // iOS handled via entitlement (media library not needed for local docs)
  }

  Future<List<Track>> getAllTracks() async {
    return HiveService.trackBox.values.toList();
  }

  Future<List<Track>> refreshLibrary({Function(double progress)? onProgress}) async {
    final ok = await ensurePermissions();
    if (!ok) throw Exception('Permissions denied');

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    final List<Track> tracks = [];
    for (var i = 0; i < songs.length; i++) {
      final s = songs[i];
      // Filter by supported formats quickly (extension check)
      final path = s.data;
      final lower = path.toLowerCase();
      if (!(lower.endsWith('.mp3') || lower.endsWith('.flac') || lower.endsWith('.wav') || lower.endsWith('.m4a'))) {
        continue;
      }
      final track = Track(
        id: s.id.toString(),
        title: (s.title.isEmpty ? 'Unknown Title' : s.title).trim(),
        artist: (s.artist ?? 'Unknown Artist').trim(),
        album: (s.album ?? 'Unknown Album').trim(),
        durationMs: s.duration ?? 0,
        path: path,
        addedAt: DateTime.now().millisecondsSinceEpoch,
        artworkPath: null, // can be extracted lazily
        genre: s.genre,
      );
      tracks.add(track);
      onProgress?.call((i + 1) / songs.length);
    }

    // Write to Hive (replace existing) using batch
    final box = HiveService.trackBox;
    await box.clear();
    await box.addAll(tracks);

    // Build aggregated album/artist indexes
    await _rebuildIndexes(tracks);
    return tracks;
  }

  Future<void> _rebuildIndexes(List<Track> tracks) async {
    final albumBox = HiveService.albumBox;
    final artistBox = HiveService.artistBox;
    await albumBox.clear();
    await artistBox.clear();

    final byAlbum = groupBy(tracks, (Track t) => '${t.album}:::${t.artist}');
    for (final entry in byAlbum.entries) {
      final first = entry.value.first;
      albumBox.add(Album(
        id: entry.key,
        title: first.album,
        artist: first.artist,
        trackCount: entry.value.length,
      ));
    }
    final byArtist = groupBy(tracks, (Track t) => t.artist);
    for (final entry in byArtist.entries) {
      artistBox.add(Artist(
        id: entry.key,
        name: entry.key,
        trackCount: entry.value.length,
      ));
    }
  }

  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return getAllTracks();
    final lower = query.toLowerCase();
    return HiveService.trackBox.values.where((t) {
      return t.title.toLowerCase().contains(lower) ||
          t.artist.toLowerCase().contains(lower) ||
          t.album.toLowerCase().contains(lower);
    }).toList();
  }

  Future<List<Track>> getRecent({int limit = 20}) async {
    final all = HiveService.trackBox.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return all.take(limit).toList();
  }
}
