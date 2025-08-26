class Playlist {
  final String id;
  final String name;
  final String? description;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverArt;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
    this.coverArt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverArt': coverArt,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      songIds: List<String>.from(json['songIds']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      coverArt: json['coverArt'],
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverArt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverArt: coverArt ?? this.coverArt,
    );
  }
}
