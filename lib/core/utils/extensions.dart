// Utility extensions for Lyra

/// Duration formatting extension
extension DurationExtension on Duration {
  /// Format duration as mm:ss or hh:mm:ss
  String get formatted {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

/// Integer duration extension (for seconds)
extension IntDurationExtension on int {
  /// Convert seconds to formatted duration string
  String get formattedDuration {
    return Duration(seconds: this).formatted;
  }

  /// Convert seconds to Duration
  Duration get seconds => Duration(seconds: this);
}

/// String utilities
extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
