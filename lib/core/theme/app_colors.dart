import 'package:flutter/material.dart';

/// Color palette for Lyra
/// Modern dark theme with vibrant accents
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Accent colors
  static const Color accent = Color(0xFFF472B6); // Pink
  static const Color accentLight = Color(0xFFF9A8D4);

  // Background colors (dark theme)
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
  static const Color surfaceHighlight = Color(0xFF333333);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF737373);

  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);

  // Player gradient colors
  static const List<Color> playerGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F0F0F),
  ];

  // Shimmer colors
  static const Color shimmerBase = Color(0xFF2A2A2A);
  static const Color shimmerHighlight = Color(0xFF3A3A3A);
}
