import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/playlists_table.dart';
import 'tables/tracks_table.dart';
import '../../core/constants/app_constants.dart';

part 'app_database.g.dart';

/// Main database class for Lyra
/// Handles all local data persistence for playlists and tracks
@DriftDatabase(tables: [Playlists, Tracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// Singleton instance
  static final AppDatabase instance = AppDatabase._();

  /// Database schema version - increment when schema changes
  @override
  int get schemaVersion => 1;

  /// Open the database connection
  static QueryExecutor _openConnection() {
    return driftDatabase(name: AppConstants.databaseName);
  }

  /// Schema migration strategy
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
    );
  }

  // ============ Playlist Operations ============

  /// Get all playlists ordered by most recently updated
  Future<List<Playlist>> getAllPlaylists() {
    return (select(playlists)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// Get a single playlist by ID
  Future<Playlist?> getPlaylistById(int id) {
    return (select(playlists)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get a single playlist by UUID
  Future<Playlist?> getPlaylistByUuid(String uuid) {
    return (select(
      playlists,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Create a new playlist
  Future<int> createPlaylist(PlaylistsCompanion playlist) {
    return into(playlists).insert(playlist);
  }

  /// Update an existing playlist
  Future<bool> updatePlaylist(Playlist playlist) {
    return update(playlists).replace(playlist);
  }

  /// Delete a playlist by ID (cascades to tracks)
  Future<int> deletePlaylist(int id) {
    return (delete(playlists)..where((t) => t.id.equals(id))).go();
  }

  /// Watch all playlists (reactive stream)
  Stream<List<Playlist>> watchAllPlaylists() {
    return (select(playlists)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // ============ Track Operations ============

  /// Get all tracks for a playlist ordered by position
  Future<List<Track>> getTracksForPlaylist(int playlistId) {
    return (select(tracks)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  /// Watch tracks for a playlist (reactive stream)
  Stream<List<Track>> watchTracksForPlaylist(int playlistId) {
    return (select(tracks)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Add a track to a playlist
  Future<int> addTrackToPlaylist(TracksCompanion track) {
    return into(tracks).insert(track);
  }

  /// Get track count for a playlist
  Future<int> getTrackCountForPlaylist(int playlistId) async {
    final count = tracks.id.count();
    final query = selectOnly(tracks)
      ..addColumns([count])
      ..where(tracks.playlistId.equals(playlistId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get the next position for a new track in a playlist
  Future<int> getNextTrackPosition(int playlistId) async {
    final maxPos = tracks.position.max();
    final query = selectOnly(tracks)
      ..addColumns([maxPos])
      ..where(tracks.playlistId.equals(playlistId));
    final result = await query.getSingleOrNull();
    final currentMax = result?.read(maxPos);
    return (currentMax ?? -1) + 1;
  }

  /// Update a track
  Future<bool> updateTrack(Track track) {
    return update(tracks).replace(track);
  }

  /// Delete a track by ID
  Future<int> deleteTrack(int id) {
    return (delete(tracks)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all tracks for a playlist
  Future<int> deleteTracksForPlaylist(int playlistId) {
    return (delete(tracks)..where((t) => t.playlistId.equals(playlistId))).go();
  }

  /// Reorder tracks in a playlist
  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) async {
    final tracksList = await getTracksForPlaylist(playlistId);
    if (oldIndex < 0 ||
        oldIndex >= tracksList.length ||
        newIndex < 0 ||
        newIndex >= tracksList.length) {
      return;
    }

    await transaction(() async {
      // Get track being moved
      final movedTrack = tracksList[oldIndex];

      if (oldIndex < newIndex) {
        // Moving down: shift tracks between oldIndex and newIndex up
        for (int i = oldIndex + 1; i <= newIndex; i++) {
          await (update(tracks)..where((t) => t.id.equals(tracksList[i].id)))
              .write(TracksCompanion(position: Value(i - 1)));
        }
      } else {
        // Moving up: shift tracks between newIndex and oldIndex down
        for (int i = newIndex; i < oldIndex; i++) {
          await (update(tracks)..where((t) => t.id.equals(tracksList[i].id)))
              .write(TracksCompanion(position: Value(i + 1)));
        }
      }

      // Update the moved track's position
      await (update(tracks)..where((t) => t.id.equals(movedTrack.id))).write(
        TracksCompanion(position: Value(newIndex)),
      );
    });
  }

  /// Check if a track already exists in a playlist
  Future<bool> trackExistsInPlaylist(int playlistId, String youtubeId) async {
    final result =
        await (select(tracks)..where(
              (t) =>
                  t.playlistId.equals(playlistId) &
                  t.youtubeId.equals(youtubeId),
            ))
            .getSingleOrNull();
    return result != null;
  }
}
