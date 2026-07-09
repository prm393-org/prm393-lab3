import 'package:equatable/equatable.dart';

/// Số lượng bài báo trong một năm — dữ liệu cho biểu đồ xu hướng (4.3).
class TrendPoint extends Equatable {
  final int year;
  final int count;

  const TrendPoint({required this.year, required this.count});

  @override
  List<Object?> get props => [year, count];
}
