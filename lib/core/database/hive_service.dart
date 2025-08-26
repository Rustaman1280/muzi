import 'package:hive_flutter/hive_flutter.dart';
import '../models/library_models.dart';

class HiveService {
  static const String _songBox = 'songs';
  static const String _trackBox = 'tracks';
  static const String _albumBox = 'albums';
  static const String _artistBox = 'artists';
  static const String _playlistBox = 'playlists';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
  // Register adapters (guard against double registration)
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TrackAdapter());
  if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AlbumAdapter());
  if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(ArtistAdapter());
  if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PlaylistAdapter());

  // Open boxes
  await Hive.openBox(_songBox); // (legacy / remove if unused)
  await Hive.openBox(_settingsBox);
  await Hive.openBox<Track>(_trackBox);
  await Hive.openBox<Album>(_albumBox);
  await Hive.openBox<Artist>(_artistBox);
  // Open playlists only once with the correct typed box
  await Hive.openBox<Playlist>(_playlistBox);
  }

  static Box get songBox => Hive.box(_songBox);
  static Box get playlistBox => Hive.box(_playlistBox);
  static Box get settingsBox => Hive.box(_settingsBox);
  static Box<Track> get trackBox => Hive.box<Track>(_trackBox);
  static Box<Album> get albumBox => Hive.box<Album>(_albumBox);
  static Box<Artist> get artistBox => Hive.box<Artist>(_artistBox);

  static Future<void> close() async {
    await Hive.close();
  }
}
