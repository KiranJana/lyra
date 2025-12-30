import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../models/playlist.dart' as model;

/// Provider for the AppDatabase singleton
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Provider for playlist repository
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(ref.watch(databaseProvider));
});

/// Repository for playlist operations
class PlaylistRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PlaylistRepository(this._db);

  /// Get all playlists as a stream (reactive)
  Stream<List<model.Playlist>> watchAllPlaylists() {
    return _db.watchAllPlaylists().asyncMap((playlists) async {
      // Fetch track counts for each playlist
      final result = <model.Playlist>[];
      for (final playlist in playlists) {
        final trackCount = await _db.getTrackCountForPlaylist(playlist.id);
        result.add(_toModel(playlist, trackCount));
      }
      return result;
    });
  }

  /// Get all playlists (one-time fetch)
  Future<List<model.Playlist>> getAllPlaylists() async {
    final playlists = await _db.getAllPlaylists();
    final result = <model.Playlist>[];
    for (final playlist in playlists) {
      final trackCount = await _db.getTrackCountForPlaylist(playlist.id);
      result.add(_toModel(playlist, trackCount));
    }
    return result;
  }

  /// Get a playlist by ID
  Future<model.Playlist?> getPlaylistById(int id) async {
    final playlist = await _db.getPlaylistById(id);
    if (playlist == null) return null;
    final trackCount = await _db.getTrackCountForPlaylist(id);
    return _toModel(playlist, trackCount);
  }

  /// Create a new playlist
  Future<model.Playlist> createPlaylist(String name) async {
    final uuid = _uuid.v4();
    final now = DateTime.now();

    final id = await _db.createPlaylist(
      PlaylistsCompanion.insert(
        uuid: uuid,
        name: name,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return model.Playlist(
      id: id,
      uuid: uuid,
      name: name,
      createdAt: now,
      updatedAt: now,
      trackCount: 0,
    );
  }

  /// Update a playlist's name
  Future<void> updatePlaylistName(int id, String newName) async {
    final playlist = await _db.getPlaylistById(id);
    if (playlist == null) return;

    await _db.updatePlaylist(
      playlist.copyWith(name: newName, updatedAt: DateTime.now()),
    );
  }

  /// Update a playlist's cover art
  Future<void> updatePlaylistCover(int id, String? coverUrl) async {
    final playlist = await _db.getPlaylistById(id);
    if (playlist == null) return;

    await _db.updatePlaylist(
      playlist.copyWith(
        coverArtUrl: Value(coverUrl),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Delete a playlist
  Future<void> deletePlaylist(int id) async {
    // First delete all tracks (although foreign key should handle this)
    await _db.deleteTracksForPlaylist(id);
    await _db.deletePlaylist(id);
  }

  /// Convert database entity to model
  model.Playlist _toModel(Playlist dbPlaylist, int trackCount) {
    return model.Playlist(
      id: dbPlaylist.id,
      uuid: dbPlaylist.uuid,
      name: dbPlaylist.name,
      coverArtUrl: dbPlaylist.coverArtUrl,
      createdAt: dbPlaylist.createdAt,
      updatedAt: dbPlaylist.updatedAt,
      trackCount: trackCount,
    );
  }
}
