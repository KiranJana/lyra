/// Playlist model representing a collection of tracks
class Playlist {
  final int? id;
  final String uuid;
  final String name;
  final String? coverArtUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trackCount;

  const Playlist({
    this.id,
    required this.uuid,
    required this.name,
    this.coverArtUrl,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
  });

  /// Create a copy with updated fields
  Playlist copyWith({
    int? id,
    String? uuid,
    String? name,
    String? coverArtUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trackCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'coverArtUrl': coverArtUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'trackCount': trackCount,
    };
  }

  /// Create from JSON map
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int?,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      coverArtUrl: json['coverArtUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      trackCount: json['trackCount'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() {
    return 'Playlist{uuid: $uuid, name: $name, trackCount: $trackCount}';
  }
}
