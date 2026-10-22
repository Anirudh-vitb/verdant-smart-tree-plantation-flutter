import 'package:flutter/material.dart';

/// Central colour palette for the app.
///
/// Every screen and widget reads colours from here (or from the [ThemeData]
/// built from them) so the visual language stays consistent.
abstract final class AppColors {
  static const Color forest = Color(0xFF1B4332);
  static const Color forestDark = Color(0xFF0F2A1F);
  static const Color leaf = Color(0xFF52B788);
  static const Color leafSoft = Color(0xFFD8F3DC);
  static const Color background = Color(0xFFF7F5EF);
  static const Color surface = Colors.white;
  static const Color outline = Color(0xFFE3E0D6);
  static const Color textPrimary = Color(0xFF1F2A24);
  static const Color textMuted = Color(0xFF5B665F);

  // Health status colours. Foreground/background pairs meet WCAG AA contrast.
  static const Color healthyFg = Color(0xFF1E5B3F);
  static const Color healthyBg = Color(0xFFD8F3DC);
  static const Color attentionFg = Color(0xFF7A4F00);
  static const Color attentionBg = Color(0xFFFFEFC2);
  static const Color criticalFg = Color(0xFFA3201A);
  static const Color criticalBg = Color(0xFFFDE4E2);

  static const Color water = Color(0xFF1D6FA3);
  static const Color waterBg = Color(0xFFE1F0FA);
}
