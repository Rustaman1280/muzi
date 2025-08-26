import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart';

class MusicQueryService {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static Future<bool> checkPermissions() async {
    return await _audioQuery.permissionsStatus();
  }

  static Future<bool> requestPermissions() async {
    return await _audioQuery.permissionsRequest();
  }

  static Future<List<Song>> getAllSongs() async {
    try {
      final List<SongModel> songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      return songs.map((song) => _convertToSong(song)).toList();
    } catch (e) {
      print('Error fetching songs: $e');
      return [];
    }
  }

  static Future<List<AlbumModel>> getAllAlbums() async {
    try {
      return await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    } catch (e) {
      print('Error fetching albums: $e');
      return [];
    }
  }

  static Future<List<ArtistModel>> getAllArtists() async {
    try {
      return await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    } catch (e) {
      print('Error fetching artists: $e');
      return [];
    }
  }

  static Future<List<Song>> getSongsByAlbum(int albumId) async {
    try {
      final List<SongModel> songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        albumId,
      );

      return songs.map((song) => _convertToSong(song)).toList();
    } catch (e) {
      print('Error fetching songs from album: $e');
      return [];
    }
  }

  static Future<List<Song>> getSongsByArtist(int artistId) async {
    try {
      final List<SongModel> songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ARTIST_ID,
        artistId,
      );

      return songs.map((song) => _convertToSong(song)).toList();
    } catch (e) {
      print('Error fetching songs from artist: $e');
      return [];
    }
  }

  static Song _convertToSong(SongModel songModel) {
    return Song(
      id: songModel.id.toString(),
      title: songModel.title,
      artist: songModel.artist ?? 'Unknown Artist',
      album: songModel.album ?? 'Unknown Album',
      filePath: songModel.data,
      duration: Duration(milliseconds: songModel.duration ?? 0),
      trackNumber: songModel.track,
      genre: songModel.genre,
    );
  }
}
