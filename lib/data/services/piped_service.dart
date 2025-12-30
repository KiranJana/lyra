import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../models/search_result.dart';

/// Provider for Piped service
final pipedServiceProvider = Provider<PipedService>((ref) {
  return PipedService();
});

/// Service for interacting with Piped API
/// Piped provides YouTube search and stream URL extraction without needing API keys
class PipedService {
  final Dio _dio;
  int _currentInstanceIndex = 0;

  PipedService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(
      seconds: ApiConstants.requestTimeout,
    );
    _dio.options.receiveTimeout = const Duration(
      seconds: ApiConstants.requestTimeout,
    );
  }

  /// Get the current Piped instance URL
  String get _currentInstance =>
      ApiConstants.pipedInstances[_currentInstanceIndex];

  /// Switch to the next Piped instance (for fallback)
  void _switchInstance() {
    _currentInstanceIndex =
        (_currentInstanceIndex + 1) % ApiConstants.pipedInstances.length;
  }

  /// Search for videos on YouTube via Piped
  /// filter options: all, videos, channels, playlists, music_songs, music_videos, music_albums, music_playlists
  Future<List<SearchResult>> search(
    String query, {
    String filter = 'all', // Changed from music_songs for better compatibility
  }) async {
    if (query.trim().isEmpty) return [];

    Exception? lastError;

    // Reset to first instance for each new search
    _currentInstanceIndex = 0;

    // Try each instance until one works
    for (
      int attempt = 0;
      attempt < ApiConstants.pipedInstances.length;
      attempt++
    ) {
      final instance = _currentInstance;
      try {
        print('[PipedService] Trying search on: $instance');

        final response = await _dio.get(
          '$instance/search',
          queryParameters: {'q': query, 'filter': filter},
        );

        if (response.statusCode == 200 && response.data != null) {
          final items = response.data['items'] as List? ?? [];
          print('[PipedService] Got ${items.length} results from $instance');

          // Filter out non-video items and map to SearchResult
          final results = items
              .where((item) => item['type'] == 'stream')
              .map((item) => SearchResult.fromPipedJson(item))
              .where((result) => !result.isLive) // Filter out live streams
              .toList();

          print(
            '[PipedService] Filtered to ${results.length} playable streams',
          );
          return results;
        } else {
          print(
            '[PipedService] Bad response from $instance: ${response.statusCode}',
          );
        }
      } catch (e) {
        print('[PipedService] Error from $instance: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        _switchInstance(); // Try next instance
      }
    }

    throw lastError ?? Exception('All Piped instances failed');
  }

  /// Get stream information for a video
  /// Returns the audio stream URL and other metadata
  Future<StreamInfo> getStreamInfo(String videoId) async {
    Exception? lastError;

    for (
      int attempt = 0;
      attempt < ApiConstants.pipedInstances.length;
      attempt++
    ) {
      try {
        final response = await _dio.get('$_currentInstance/streams/$videoId');

        if (response.statusCode == 200 && response.data != null) {
          return StreamInfo.fromJson(response.data);
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        _switchInstance();
      }
    }

    throw lastError ?? Exception('Failed to get stream info');
  }

  /// Get just the audio stream URL for a video
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final streamInfo = await getStreamInfo(videoId);
      return streamInfo.bestAudioStreamUrl;
    } catch (e) {
      return null;
    }
  }

  /// Get trending music
  Future<List<SearchResult>> getTrending({String region = 'US'}) async {
    Exception? lastError;

    for (
      int attempt = 0;
      attempt < ApiConstants.pipedInstances.length;
      attempt++
    ) {
      try {
        final response = await _dio.get(
          '$_currentInstance/trending',
          queryParameters: {'region': region},
        );

        if (response.statusCode == 200 && response.data is List) {
          return (response.data as List)
              .where((item) => item['type'] == 'stream')
              .map((item) => SearchResult.fromPipedJson(item))
              .take(20)
              .toList();
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        _switchInstance();
      }
    }

    throw lastError ?? Exception('Failed to get trending');
  }
}

/// Stream information from Piped API
class StreamInfo {
  final String title;
  final String? uploader;
  final String? uploaderUrl;
  final String? thumbnailUrl;
  final int? duration; // in seconds
  final List<AudioStream> audioStreams;
  final String? hlsUrl; // HLS stream for live content

  StreamInfo({
    required this.title,
    this.uploader,
    this.uploaderUrl,
    this.thumbnailUrl,
    this.duration,
    required this.audioStreams,
    this.hlsUrl,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    final audioStreamsList = (json['audioStreams'] as List? ?? [])
        .map((s) => AudioStream.fromJson(s))
        .where((s) => s.url != null)
        .toList();

    // Sort by quality (higher bitrate first)
    audioStreamsList.sort((a, b) => (b.bitrate ?? 0).compareTo(a.bitrate ?? 0));

    return StreamInfo(
      title: json['title'] ?? 'Unknown',
      uploader: json['uploader'],
      uploaderUrl: json['uploaderUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      audioStreams: audioStreamsList,
      hlsUrl: json['hls'],
    );
  }

  /// Get the best quality audio stream URL
  /// iOS prefers M4A/MP4, Android can play Opus/WebM too
  String? get bestAudioStreamUrl {
    if (audioStreams.isEmpty) return hlsUrl;

    print('[StreamInfo] Available audio streams:');
    for (final s in audioStreams) {
      print('  - ${s.mimeType}, ${s.bitrate}bps, ${s.quality}');
    }

    // For iOS compatibility, prefer M4A/MP4 over Opus/WebM
    final m4aStream = audioStreams
        .where(
          (s) =>
              s.mimeType?.contains('mp4') == true ||
              s.mimeType?.contains('m4a') == true ||
              s.mimeType?.contains('aac') == true,
        )
        .firstOrNull;

    if (m4aStream != null) {
      print('[StreamInfo] Selected M4A stream: ${m4aStream.mimeType}');
      return m4aStream.url;
    }

    // Fall back to Opus/WebM if no M4A available
    final opusStream = audioStreams
        .where(
          (s) =>
              s.mimeType?.contains('opus') == true ||
              s.mimeType?.contains('webm') == true,
        )
        .firstOrNull;

    if (opusStream != null) {
      print('[StreamInfo] Selected Opus stream: ${opusStream.mimeType}');
      return opusStream.url;
    }

    // Fall back to any audio stream
    print(
      '[StreamInfo] Selected first available stream: ${audioStreams.first.mimeType}',
    );
    return audioStreams.first.url ?? hlsUrl;
  }

  /// Get a medium quality audio stream (for data saving)
  String? get mediumAudioStreamUrl {
    if (audioStreams.isEmpty) return hlsUrl;

    // Find stream around 128kbps
    final mediumStream = audioStreams
        .where((s) => (s.bitrate ?? 0) >= 96000 && (s.bitrate ?? 0) <= 160000)
        .firstOrNull;

    return mediumStream?.url ?? bestAudioStreamUrl;
  }
}

/// Audio stream information
class AudioStream {
  final String? url;
  final String? mimeType;
  final int? bitrate;
  final String? codec;
  final String? quality;

  AudioStream({
    this.url,
    this.mimeType,
    this.bitrate,
    this.codec,
    this.quality,
  });

  factory AudioStream.fromJson(Map<String, dynamic> json) {
    return AudioStream(
      url: json['url'],
      mimeType: json['mimeType'],
      bitrate: json['bitrate'],
      codec: json['codec'],
      quality: json['quality'],
    );
  }
}
