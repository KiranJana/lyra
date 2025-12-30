import 'dart:io' show Platform;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/search_result.dart' as model;

/// Provider for YouTube service
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  return YouTubeService();
});

/// Service for interacting with YouTube via youtube_explode_dart
/// This extracts direct Google Video URLs without needing a proxy
class YouTubeService {
  final YoutubeExplode _yt;

  YouTubeService() : _yt = YoutubeExplode();

  /// Search for videos on YouTube
  Future<List<model.SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      print('[YouTubeService] Searching for: $query');

      final searchResults = await _yt.search.search(query);

      print('[YouTubeService] Got ${searchResults.length} results');

      return searchResults
          .take(20)
          .map(
            (video) => model.SearchResult(
              videoId: video.id.value,
              title: video.title,
              uploaderName: video.author,
              thumbnailUrl: video.thumbnails.highResUrl,
              duration: video.duration?.inSeconds,
              views: null,
              uploadedDate: null,
              isLive: video.isLive,
            ),
          )
          .where((result) => !result.isLive)
          .toList();
    } catch (e) {
      print('[YouTubeService] Search error: $e');
      rethrow;
    }
  }

  /// Get the best audio stream URL for a video
  /// Returns a direct Google Video URL
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      print('[YouTubeService] Getting streams for: $videoId');
      print('[YouTubeService] Platform: ${Platform.isIOS ? "iOS" : "Android"}');

      // Get the stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      print(
        '[YouTubeService] Available audio streams: ${manifest.audioOnly.length}',
      );
      for (final stream in manifest.audioOnly.take(6)) {
        print(
          '  - ${stream.container.name}, ${stream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps, ${stream.audioCodec}',
        );
      }

      // Get audio streams
      final audioStreams = manifest.audioOnly.toList();

      if (audioStreams.isEmpty) {
        print('[YouTubeService] No audio streams found');
        return null;
      }

      // Sort by bitrate (highest first)
      audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));

      // For iOS, prefer M4A/AAC format
      AudioOnlyStreamInfo? selectedStream;

      if (Platform.isIOS) {
        // iOS: prefer M4A/MP4 with AAC codec
        selectedStream = audioStreams
            .where(
              (s) =>
                  s.container.name.toLowerCase() == 'm4a' ||
                  s.container.name.toLowerCase() == 'mp4' ||
                  s.audioCodec.toLowerCase().contains('mp4a'),
            )
            .firstOrNull;
      }

      // Fallback to highest bitrate
      selectedStream ??= audioStreams.first;

      print(
        '[YouTubeService] Selected: ${selectedStream.container.name}, ${selectedStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps',
      );
      print('[YouTubeService] Codec: ${selectedStream.audioCodec}');
      print('[YouTubeService] URL host: ${selectedStream.url.host}');

      return selectedStream.url.toString();
    } catch (e) {
      print('[YouTubeService] Stream error: $e');
      return null;
    }
  }

  /// Get the audio stream info for a video
  /// Used by the local proxy server to forward requests
  Future<({Uri url, int contentLength, String container})?> getAudioStreamInfo(
    String videoId,
  ) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.toList();

      if (audioStreams.isEmpty) return null;

      // 1. Sort by bitrate first
      audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));

      // 2. Select the best stream based on Platform
      var selectedStream = audioStreams.first;

      if (Platform.isIOS) {
        // Find the best M4A/MP4 stream
        final m4aStream = audioStreams.firstWhere(
          (s) =>
              s.container.name.toLowerCase() == 'm4a' ||
              s.container.name.toLowerCase() == 'mp4',
          orElse: () => audioStreams.first,
        );
        selectedStream = m4aStream;
      }

      print(
        '[YouTubeService] Stream info: ${selectedStream.container.name}, ${selectedStream.size.totalBytes} bytes',
      );
      print('[YouTubeService] Stream URL: ${selectedStream.url}');

      return (
        url: selectedStream.url,
        contentLength: selectedStream.size.totalBytes,
        container: selectedStream.container.name,
      );
    } catch (e) {
      print('[YouTubeService] Stream info error: $e');
      return null;
    }
  }

  /// Get video info
  Future<Video?> getVideoInfo(String videoId) async {
    try {
      return await _yt.videos.get(videoId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _yt.close();
  }
}
