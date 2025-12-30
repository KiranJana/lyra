/// Track model representing a song/video
class Track {
  final String id;
  final String youtubeId;
  final String title;
  final String? artist;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int? playlistId;
  final int position;
  final DateTime? addedAt;

  const Track({
    required this.id,
    required this.youtubeId,
    required this.title,
    this.artist,
    this.thumbnailUrl,
    this.durationSeconds,
    this.playlistId,
    this.position = 0,
    this.addedAt,
  });

  /// Create a copy with updated fields
  Track copyWith({
    String? id,
    String? youtubeId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    int? durationSeconds,
    int? playlistId,
    int? position,
    DateTime? addedAt,
  }) {
    return Track(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      playlistId: playlistId ?? this.playlistId,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'youtubeId': youtubeId,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'playlistId': playlistId,
      'position': position,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  /// Create from JSON map
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      youtubeId: json['youtubeId'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      playlistId: json['playlistId'] as int?,
      position: json['position'] as int? ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          youtubeId == other.youtubeId;

  @override
  int get hashCode => youtubeId.hashCode;

  @override
  String toString() {
    return 'Track{youtubeId: $youtubeId, title: $title, artist: $artist}';
  }
}
