import 'package:equatable/equatable.dart';

/// Một trang kết quả kèm tổng số bản ghi (OpenAlex `meta.count`).
class Paged<T> extends Equatable {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;

  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  /// Còn trang sau hay không (dựa trên tổng số bản ghi đã tải).
  bool get hasMore => page * perPage < total;

  @override
  List<Object?> get props => [items, total, page, perPage];
}
