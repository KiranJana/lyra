import 'track.dart';

/// Search result model from Piped/YouTube API
class SearchResult {
  final String videoId;
  final String title;
  final String? uploaderName;
  final String? thumbnailUrl;
  final int? duration; // Duration in seconds
  final int? views;
  final String? uploadedDate;
  final bool isLive;

  const SearchResult({
    required this.videoId,
    required this.title,
    this.uploaderName,
    this.thumbnailUrl,
    this.duration,
    this.views,
    this.uploadedDate,
    this.isLive = false,
  });

  /// Create from Piped API response
  factory SearchResult.fromPipedJson(Map<String, dynamic> json) {
    // Piped returns duration in seconds
    final duration = json['duration'] as int?;

    // Get the best thumbnail
    String? thumbnailUrl;
    if (json['thumbnail'] != null) {
      thumbnailUrl = json['thumbnail'] as String;
    } else if (json['thumbnails'] != null &&
        (json['thumbnails'] as List).isNotEmpty) {
      thumbnailUrl = (json['thumbnails'] as List).first['url'] as String?;
    }

    return SearchResult(
      videoId: json['url']?.toString().replaceAll('/watch?v=', '') ?? '',
      title: json['title'] as String? ?? 'Unknown',
      uploaderName: json['uploaderName'] as String?,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      views: json['views'] as int?,
      uploadedDate: json['uploadedDate'] as String?,
      isLive: json['isLive'] as bool? ?? false,
    );
  }

  /// Convert to Track model
  Track toTrack() {
    return Track(
      id: videoId,
      youtubeId: videoId,
      title: title,
      artist: uploaderName,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId;

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() {
    return 'SearchResult{videoId: $videoId, title: $title}';
  }
}
