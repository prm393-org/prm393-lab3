import 'package:flutter/material.dart';

/// Tập trung style chữ tái sử dụng. Mở rộng khi triển khai UI.
class AppTypography {
  AppTypography._();

  static const TextStyle kpiNumber = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}
