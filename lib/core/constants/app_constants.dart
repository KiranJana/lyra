/// App-wide constants for Lyra
class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'Lyra';

  /// Database name
  static const String databaseName = 'lyra_database.db';

  /// Maximum search history items to store
  static const int maxSearchHistory = 20;

  /// Buffer size for audio pre-loading (in seconds)
  static const int audioBufferSize = 30;

  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
