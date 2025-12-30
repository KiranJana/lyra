/// API configuration constants for Lyra
class ApiConstants {
  ApiConstants._();

  /// Piped API instances for fallback
  /// Using public instances for MVP - consider self-hosting for production
  /// Last verified: December 2024
  static const List<String> pipedInstances = [
    'https://pipedapi.wireway.ch', // Verified working
    'https://pipedapi.kavin.rocks', // Primary/Official
    'https://pipedapi.adminforge.de', // Backup
  ];

  /// Default timeout for API requests in seconds
  static const int requestTimeout = 15;

  /// Search debounce duration in milliseconds
  static const int searchDebounceMs = 300;
}
