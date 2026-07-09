import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';

/// Một lựa chọn sắp xếp cho danh sách bài báo (giá trị `sort` của OpenAlex).
class WorkSortOption extends Equatable {
  final String label;
  final String value;
  const WorkSortOption(this.label, this.value);

  static const citations = WorkSortOption('Citations', 'cited_by_count:desc');
  static const newest = WorkSortOption('Newest', 'publication_date:desc');
  static const oldest = WorkSortOption('Oldest', 'publication_date:asc');

  static const all = [citations, newest, oldest];

  static WorkSortOption fromValue(String value) =>
      all.firstWhere((o) => o.value == value, orElse: () => citations);

  @override
  List<Object?> get props => [value];
}

abstract class JournalState extends Equatable {
  const JournalState();
  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {
  const JournalInitial();
}

class JournalLoading extends JournalState {
  final Topic topic;
  const JournalLoading(this.topic);

  @override
  List<Object?> get props => [topic];
}

class JournalLoaded extends JournalState {
  final List<Work> works;
  final List<TrendPoint> trend;
  final Topic topic;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final int? year;
  final WorkSortOption sort;

  const JournalLoaded({
    required this.works,
    required this.topic,
    required this.total,
    this.trend = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.year,
    this.sort = WorkSortOption.citations,
  });

  /// Các năm cho menu lọc, sắp giảm dần (mới nhất trước).
  ///
  /// Ưu tiên các năm có dữ liệu trend; nếu trend rỗng/lỗi thì dùng dải ~16 năm
  /// gần nhất để bộ lọc vẫn bấm được (không bị vô hiệu hoá).
  List<int> get availableYears {
    if (trend.isNotEmpty) {
      return trend.map((t) => t.year).toList()..sort((a, b) => b.compareTo(a));
    }
    final now = DateTime.now().year;
    return [for (var y = now; y >= now - 15; y--) y];
  }

  JournalLoaded copyWith({
    List<Work>? works,
    List<TrendPoint>? trend,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    int? year,
    bool clearYear = false,
    WorkSortOption? sort,
  }) =>
      JournalLoaded(
        works: works ?? this.works,
        trend: trend ?? this.trend,
        topic: topic,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        year: clearYear ? null : (year ?? this.year),
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props =>
      [works, trend, topic, total, hasMore, isLoadingMore, year, sort];
}

class JournalError extends JournalState {
  final String message;
  final Topic topic;
  const JournalError(this.message, this.topic);

  @override
  List<Object?> get props => [message, topic];
}
