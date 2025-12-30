import 'package:drift/drift.dart';

import 'playlists_table.dart';

/// Tracks table - stores tracks within playlists
class Tracks extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to playlist
  IntColumn get playlistId => integer().references(Playlists, #id)();

  /// YouTube video ID
  TextColumn get youtubeId => text().withLength(min: 1, max: 20)();

  /// Track title
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Artist/uploader name
  TextColumn get artist => text().nullable()();

  /// Thumbnail URL
  TextColumn get thumbnailUrl => text().nullable()();

  /// Duration in seconds
  IntColumn get durationSeconds => integer().nullable()();

  /// Position in playlist (for ordering)
  IntColumn get position => integer()();

  /// When the track was added
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}
