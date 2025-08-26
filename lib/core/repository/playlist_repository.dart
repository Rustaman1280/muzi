import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/hive_service.dart';
import '../models/library_models.dart';
import '../models/song.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref){
  return PlaylistRepository();
});

class PlaylistRepository {
  var _counter = 0; // simple id seed

  List<Playlist> getAllPlaylists() => HiveService.playlistBox.values.toList();

  Future<Playlist> createPlaylist(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final p = Playlist(
      id: 'pl_${now}_${_counter++}',
      name: name.trim(),
      trackIds: [],
      createdAt: now,
      updatedAt: now,
    );
    await HiveService.playlistBox.add(p);
    return p;
  }

  Future<void> renamePlaylist(Playlist p, String newName) async {
    p.name = newName.trim();
    p.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await p.save();
  }

  Future<void> deletePlaylist(Playlist p) async {
    await p.delete();
  }

  Future<void> addTrack(Playlist p, String trackId) async {
    if(!p.trackIds.contains(trackId)){
      p.trackIds.add(trackId);
      p.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await p.save();
    }
  }

  Future<void> removeTrack(Playlist p, String trackId) async {
    p.trackIds.remove(trackId);
    p.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await p.save();
  }

  List<Track> getTracksOf(Playlist p){
    final all = HiveService.trackBox.values;
    return all.where((t)=> p.trackIds.contains(t.id)).toList();
  }

  Song toSong(Track t) => Song(
    id: t.id,
    title: t.title,
    artist: t.artist,
    album: t.album,
    filePath: t.path,
    duration: Duration(milliseconds: t.durationMs),
    albumArt: t.artworkPath,
  );
}
