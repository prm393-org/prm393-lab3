import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Màu biểu đồ / domain theo Academic Insight Logic.
class DomainPalette {
  DomainPalette._();

  static const Map<String, Color> _byDomain = {
    'Physical Sciences': AppColors.primary,
    'Life Sciences': AppColors.tertiary,
    'Health Sciences': AppColors.secondary,
    'Social Sciences': AppColors.neutral,
  };

  static const List<Color> _fallback = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.neutral,
    Color(0xFF3B5998),
    Color(0xFF0D524D),
  ];

  static Color of(String? domain) {
    if (domain == null) return AppColors.primary;
    return _byDomain[domain] ??
        _fallback[domain.hashCode.abs() % _fallback.length];
  }

  static Color badgeBackground(String? domain) => AppColors.accentTealBg;

  static Color badgeForeground(String? domain) => AppColors.accentTealDark;
}
