import 'package:flutter/material.dart';

/// Bước nhãn năm trên trục X sao cho thưa, dễ đọc, không đè nhau.
int yearAxisStep(int span) {
  if (span <= 8) return 2;
  if (span <= 20) return 5;
  if (span <= 50) return 10;
  return 20;
}

/// Bước nhãn "tròn" cho trục đếm (số bài...) để nhãn cách đều, không đè nhau.
int countAxisStep(int maxValue) {
  if (maxValue <= 10) return 2;
  if (maxValue <= 25) return 5;
  if (maxValue <= 60) return 10;
  if (maxValue <= 120) return 20;
  return 50;
}

/// Nhãn năm cho trục X: chỉ hiện ở năm NGUYÊN nằm đúng lưới bước [step] tính
/// từ [minYear]. Nhờ vậy các mép phân số (vd minYear-0.6) bị ẩn → hết đè nhau.
Widget yearAxisLabel(double value, int minYear, int step, Color color) {
  final year = value.round();
  if ((value - year).abs() > 0.01) return const SizedBox.shrink();
  if ((year - minYear) % step != 0) return const SizedBox.shrink();
  return Text(
    year.toString(),
    style: TextStyle(fontSize: 9, color: color),
  );
}
