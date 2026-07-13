import 'package:equatable/equatable.dart';

/// Keyword của OpenAlex — phải giữ cả `id`, không chỉ tên hiển thị.
///
/// Slug trong id **không** suy ra được từ `displayName`: OpenAlex bỏ phần
/// trong ngoặc ("Transparency (behavior)" → `keywords/transparency`) và dùng
/// dấu gạch unicode. Muốn lọc `/works?filter=keywords.id:...` thì phải mang
/// theo id gốc từ API.
class Keyword extends Equatable {
  final String id;
  final String displayName;

  const Keyword({required this.id, required this.displayName});

  /// Phần slug cuối id (`.../keywords/machine-learning` → `machine-learning`).
  /// Dùng làm path param cho route `/keywords/detail/:keyword`.
  String get slug => id.split('/').last;

  /// Giá trị OpenAlex nhận trong `filter=keywords.id:...`.
  String get filterId => 'keywords/$slug';

  @override
  List<Object?> get props => [id];
}
