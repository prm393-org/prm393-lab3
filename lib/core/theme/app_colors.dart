import 'package:flutter/material.dart';

/// Academic Insight Logic — Primary / Secondary / Tertiary / Neutral.
class AppColors {
  AppColors._();

  // Brand palette (design system)
  static const Color primary = Color(0xFF1E3A5F);
  static const Color secondary = Color(0xFF4F46E5);
  static const Color tertiary = Color(0xFF14B8A6);
  static const Color neutral = Color(0xFF64748B);

  static const Color white = Color(0xFFFFFFFF);

  // Surfaces
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFEEF2FF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = primary;
  static const Color textSecondary = neutral;
  static const Color textMuted = Color(0xFF94A3B8);

  // Category / success accents
  static const Color accentTealBg = Color(0xFFCCFBF1);
  static const Color accentTealDark = Color(0xFF0D524D);

  // Semantic aliases (backward compatible)
  static const Color navy = primary;
  static const Color link = secondary;
  static const Color accentMintBg = accentTealBg;
  static const Color accentMintText = accentTealDark;
  static const Color success = tertiary;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFB91C1C);

  static const Color lightBackground = surface;
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkSurfaceMuted = Color(0xFF243B53);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkPrimaryAccent = Color(0xFF93B4D9);

  /// Nền icon / track cho từng accent (design system).
  static Color accentSurface(Color accent) {
    if (accent == primary || accent == secondary) return surfaceMuted;
    if (accent == tertiary || accent == success) return accentTealBg;
    return accent.withValues(alpha: 0.12);
  }
}
