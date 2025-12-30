import 'package:drift/drift.dart';

/// Playlists table - stores user-created playlists
class Playlists extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for sync purposes
  TextColumn get uuid => text().unique()();

  /// Playlist name
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Cover art URL (usually first track's thumbnail)
  TextColumn get coverArtUrl => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
