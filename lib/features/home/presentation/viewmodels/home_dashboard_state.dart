import 'package:equatable/equatable.dart';

import '../../../keywords/domain/entities/research_dashboard_summary.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';

/// State của dashboard tổng quan trên Home (FR 4.2) — tách khỏi [HomeState]
/// vì Home có hai phần độc lập: bộ tìm/duyệt topic và dashboard của topic đã chọn.
sealed class HomeDashboardState extends Equatable {
  const HomeDashboardState();

  @override
  List<Object?> get props => [];
}

class HomeDashboardInitial extends HomeDashboardState {
  const HomeDashboardInitial();
}

class HomeDashboardLoading extends HomeDashboardState {
  final Topic topic;

  const HomeDashboardLoading(this.topic);

  @override
  List<Object?> get props => [topic];
}

class HomeDashboardLoaded extends HomeDashboardState {
  final ResearchDashboardSummary summary;

  /// Xu hướng theo năm dùng để vẽ biểu đồ. Ưu tiên số liệu `group_by` của
  /// OpenAlex (toàn bộ topic); nếu request đó lỗi thì rơi về trend dựng từ mẫu.
  final List<TrendPoint> trend;

  /// Danh sách bài báo để người dùng tap mở Publication Detail.
  final List<Work> publications;

  /// Khác null khi trend chỉ là ước lượng từ mẫu 100 bài.
  final String? trendWarning;

  const HomeDashboardLoaded({
    required this.summary,
    required this.trend,
    required this.publications,
    this.trendWarning,
  });

  Topic get topic => summary.topic;

  @override
  List<Object?> get props => [summary, trend, publications, trendWarning];
}

class HomeDashboardEmpty extends HomeDashboardState {
  final Topic topic;

  const HomeDashboardEmpty(this.topic);

  @override
  List<Object?> get props => [topic];
}

class HomeDashboardError extends HomeDashboardState {
  final String message;
  final Topic topic;

  const HomeDashboardError(this.message, this.topic);

  @override
  List<Object?> get props => [message, topic];
}
