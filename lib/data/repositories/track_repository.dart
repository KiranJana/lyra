import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../models/track.dart' as model;
import '../../models/search_result.dart';
import 'playlist_repository.dart';

/// Provider for track repository
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository(ref.watch(databaseProvider));
});

/// Repository for track operations
class TrackRepository {
  final AppDatabase _db;

  TrackRepository(this._db);

  /// Watch tracks for a playlist (reactive stream)
  Stream<List<model.Track>> watchTracksForPlaylist(int playlistId) {
    return _db.watchTracksForPlaylist(playlistId).map((tracks) {
      return tracks.map(_toModel).toList();
    });
  }

  /// Get all tracks for a playlist
  Future<List<model.Track>> getTracksForPlaylist(int playlistId) async {
    final tracks = await _db.getTracksForPlaylist(playlistId);
    return tracks.map(_toModel).toList();
  }

  /// Add a track to a playlist from a search result
  Future<model.Track> addTrackToPlaylist(
    int playlistId,
    SearchResult searchResult,
  ) async {
    // Check if track already exists
    final exists = await _db.trackExistsInPlaylist(
      playlistId,
      searchResult.videoId,
    );
    if (exists) {
      throw Exception('Track already exists in playlist');
    }

    // Get next position
    final position = await _db.getNextTrackPosition(playlistId);

    // Insert track
    final id = await _db.addTrackToPlaylist(
      TracksCompanion.insert(
        playlistId: playlistId,
        youtubeId: searchResult.videoId,
        title: searchResult.title,
        artist: Value(searchResult.uploaderName),
        thumbnailUrl: Value(searchResult.thumbnailUrl),
        durationSeconds: Value(searchResult.duration),
        position: position,
        addedAt: Value(DateTime.now()),
      ),
    );

    return model.Track(
      id: id.toString(),
      youtubeId: searchResult.videoId,
      title: searchResult.title,
      artist: searchResult.uploaderName,
      thumbnailUrl: searchResult.thumbnailUrl,
      durationSeconds: searchResult.duration,
      playlistId: playlistId,
      position: position,
      addedAt: DateTime.now(),
    );
  }

  /// Add a track to a playlist from a Track model
  Future<model.Track> addTrack(int playlistId, model.Track track) async {
    // Check if track already exists
    final exists = await _db.trackExistsInPlaylist(playlistId, track.youtubeId);
    if (exists) {
      throw Exception('Track already exists in playlist');
    }

    // Get next position
    final position = await _db.getNextTrackPosition(playlistId);

    // Insert track
    final id = await _db.addTrackToPlaylist(
      TracksCompanion.insert(
        playlistId: playlistId,
        youtubeId: track.youtubeId,
        title: track.title,
        artist: Value(track.artist),
        thumbnailUrl: Value(track.thumbnailUrl),
        durationSeconds: Value(track.durationSeconds),
        position: position,
        addedAt: Value(DateTime.now()),
      ),
    );

    return track.copyWith(
      id: id.toString(),
      playlistId: playlistId,
      position: position,
      addedAt: DateTime.now(),
    );
  }

  /// Remove a track from a playlist
  Future<void> removeTrack(int trackId) async {
    await _db.deleteTrack(trackId);
  }

  /// Reorder tracks in a playlist
  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) async {
    await _db.reorderTracks(playlistId, oldIndex, newIndex);
  }

  /// Check if a track exists in a playlist
  Future<bool> trackExistsInPlaylist(int playlistId, String youtubeId) {
    return _db.trackExistsInPlaylist(playlistId, youtubeId);
  }

  /// Get track count for a playlist
  Future<int> getTrackCount(int playlistId) {
    return _db.getTrackCountForPlaylist(playlistId);
  }

  /// Convert database entity to model
  model.Track _toModel(Track dbTrack) {
    return model.Track(
      id: dbTrack.id.toString(),
      youtubeId: dbTrack.youtubeId,
      title: dbTrack.title,
      artist: dbTrack.artist,
      thumbnailUrl: dbTrack.thumbnailUrl,
      durationSeconds: dbTrack.durationSeconds,
      playlistId: dbTrack.playlistId,
      position: dbTrack.position,
      addedAt: dbTrack.addedAt,
    );
  }
}
