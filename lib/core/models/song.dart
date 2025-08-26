class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArt;
  final String filePath;
  final Duration duration;
  final int? trackNumber;
  final String? genre;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArt,
    required this.filePath,
    required this.duration,
    this.trackNumber,
    this.genre,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArt': albumArt,
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'trackNumber': trackNumber,
      'genre': genre,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      albumArt: json['albumArt'],
      filePath: json['filePath'],
      duration: Duration(milliseconds: json['duration']),
      trackNumber: json['trackNumber'],
      genre: json['genre'],
    );
  }

  // Helpers for audio_service integration
  Map<String, dynamic> toExtras() => {
        'albumArt': albumArt,
        'trackNumber': trackNumber,
        'genre': genre,
        'filePath': filePath,
      };
}

// MediaItem conversion kept external to avoid mandatory audio_service import here
// (See audio handler for conversion utilities.)
