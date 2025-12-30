import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'youtube_service.dart';

/// Provider for the proxy service
final proxyServiceProvider = Provider<ProxyService>((ref) {
  return ProxyService(ref.read(youtubeServiceProvider));
});

/// A local proxy server that streams audio from YouTube
/// This bypasses iOS network restrictions by serving content from localhost
/// while the Dart code handles the complex YouTube connection/headers.
class ProxyService {
  final YouTubeService _youtubeService;
  HttpServer? _server;
  int _port = 0;

  ProxyService(this._youtubeService);

  /// Start the proxy server
  Future<void> start() async {
    if (_server != null) return;

    try {
      // Bind to localhost on an ephemeral port
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      print('[ProxyService] Server running on http://127.0.0.1:$_port');

      _server!.listen(
        _handleRequest,
        onError: (e) => print('[ProxyService] Server error: $e'),
      );
    } catch (e) {
      print('[ProxyService] Failed to start server: $e');
    }
  }

  /// Get the proxy URL for a video ID
  String getStreamUrl(String videoId) {
    if (_port == 0) {
      print('[ProxyService] Warning: Server not running, returning empty');
      return '';
    }
    return 'http://127.0.0.1:$_port/stream?id=$videoId';
  }

  /// Handle incoming requests
  Future<void> _handleRequest(HttpRequest request) async {
    // Only handle /stream requests
    if (request.uri.path != '/stream') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final videoId = request.uri.queryParameters['id'];
    if (videoId == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    print('[ProxyService] Handling stream request for $videoId');

    try {
      // Get the audio stream from YouTube Service
      final result = await _youtubeService.getAudioStream(videoId);

      if (result == null) {
        print('[ProxyService] No stream found for $videoId');
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final stream = result.stream;
      final totalLength = result.contentLength;
      final container = result.container;

      // Determine content type
      final mimeType = container == 'm4a' || container == 'mp4'
          ? 'audio/mp4'
          : 'audio/webm';

      request.response.headers.contentType = ContentType.parse(mimeType);
      request.response.headers.set('Accept-Ranges', 'bytes');

      int start = 0;
      int contentLengthToServe = totalLength;

      // Handle Range Requests (Critical for iOS AVPlayer)
      final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

      if (rangeHeader != null) {
        // Simple range handling (from X to END)
        // iOS often requests "bytes=0-1" first to probe
        final ranges = rangeHeader.replaceFirst('bytes=', '').split('-');
        start = int.parse(ranges[0]);
        final end = ranges.length > 1 && ranges[1].isNotEmpty
            ? int.parse(ranges[1])
            : totalLength - 1;

        contentLengthToServe = end - start + 1;

        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$totalLength',
        );
        request.response.headers.contentLength = contentLengthToServe;

        print(
          '[ProxyService] Serving range: $start-$end ($contentLengthToServe bytes)',
        );

        if (start > 0) {
          print(
            '[ProxyService] Warning: Seek not fully supported, piping from 0',
          );
        }
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentLength = totalLength;
      }

      // Use manual stream slicing to serve exact range
      final slicedStream = _createSlicedStream(
        stream,
        start,
        contentLengthToServe,
      );

      await request.response.addStream(slicedStream);
      await request.response.close();
      print('[ProxyService] Stream finished for $videoId');
    } catch (e) {
      print('[ProxyService] Error streaming video: $e');
      try {
        if (!request.response.connectionInfo!.remoteAddress.address.isEmpty) {
          // Only try to set status if headers aren't sent, but we can't check that easily
          // so we just close.
          await request.response.close();
        }
      } catch (_) {}
    }
  }

  /// Slice a stream to return only the requested range
  Stream<List<int>> _createSlicedStream(
    Stream<List<int>> input,
    int start,
    int length,
  ) async* {
    int currentPos = 0;
    int bytesRemaining = length;

    await for (final chunk in input) {
      if (bytesRemaining <= 0) break;

      final chunkEnd = currentPos + chunk.length;

      if (chunkEnd > start) {
        // This chunk contains needed data or part of it
        int chunkStartOffset = 0;
        if (currentPos < start) {
          chunkStartOffset = start - currentPos;
        }

        final data = chunk.sublist(chunkStartOffset);

        if (data.length > bytesRemaining) {
          yield data.sublist(0, bytesRemaining);
          bytesRemaining = 0;
        } else {
          yield data;
          bytesRemaining -= data.length;
        }
      }

      currentPos += chunk.length;
    }
  }

  /// Stop the server
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _port = 0;
  }
}
