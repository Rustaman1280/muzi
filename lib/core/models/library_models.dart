import 'package:hive/hive.dart';

// Code generation placeholder removed; manual adapters below.

@HiveType(typeId: 10)
class Track extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String artist;
  @HiveField(3)
  String album;
  @HiveField(4)
  int durationMs;
  @HiveField(5)
  String path;
  @HiveField(6)
  int addedAt; // epoch ms
  @HiveField(7)
  String? artworkPath;
  @HiveField(8)
  String? genre;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.path,
    required this.addedAt,
    this.artworkPath,
    this.genre,
  });
}

class TrackAdapter extends TypeAdapter<Track> {
  @override
  final int typeId = 10;
  @override
  Track read(BinaryReader reader) {
    return Track(
      id: reader.readString(),
      title: reader.readString(),
      artist: reader.readString(),
      album: reader.readString(),
      durationMs: reader.readInt(),
      path: reader.readString(),
      addedAt: reader.readInt(),
      artworkPath: reader.read() as String?,
      genre: reader.read() as String?,
    );
  }
  @override
  void write(BinaryWriter writer, Track obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.artist)
      ..writeString(obj.album)
      ..writeInt(obj.durationMs)
      ..writeString(obj.path)
      ..writeInt(obj.addedAt)
      ..write(obj.artworkPath)
      ..write(obj.genre);
  }
}

@HiveType(typeId: 11)
class Album extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String artist;
  @HiveField(3)
  String? artworkPath;
  @HiveField(4)
  int trackCount;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkPath,
    required this.trackCount,
  });
}

class AlbumAdapter extends TypeAdapter<Album> {
  @override
  final int typeId = 11;
  @override
  Album read(BinaryReader reader) => Album(
        id: reader.readString(),
        title: reader.readString(),
        artist: reader.readString(),
        artworkPath: reader.read() as String?,
        trackCount: reader.readInt(),
      );
  @override
  void write(BinaryWriter writer, Album obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.artist)
      ..write(obj.artworkPath)
      ..writeInt(obj.trackCount);
  }
}

@HiveType(typeId: 12)
class Artist extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  int trackCount;

  Artist({required this.id, required this.name, required this.trackCount});
}

class ArtistAdapter extends TypeAdapter<Artist> {
  @override
  final int typeId = 12;
  @override
  Artist read(BinaryReader reader) => Artist(
        id: reader.readString(),
        name: reader.readString(),
        trackCount: reader.readInt(),
      );
  @override
  void write(BinaryWriter writer, Artist obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeInt(obj.trackCount);
  }
}

@HiveType(typeId: 13)
class Playlist extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  List<String> trackIds;
  @HiveField(3)
  int createdAt;
  @HiveField(4)
  int updatedAt;

  Playlist({
    required this.id,
    required this.name,
    required this.trackIds,
    required this.createdAt,
    required this.updatedAt,
  });
}

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 13;
  @override
  Playlist read(BinaryReader reader) => Playlist(
        id: reader.readString(),
        name: reader.readString(),
        trackIds: (reader.readList().cast<String>()),
        createdAt: reader.readInt(),
        updatedAt: reader.readInt(),
      );
  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeList(obj.trackIds)
      ..writeInt(obj.createdAt)
      ..writeInt(obj.updatedAt);
  }
}
