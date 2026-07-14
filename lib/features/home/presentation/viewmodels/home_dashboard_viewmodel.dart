import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/get_topic_trend.dart';
import '../../../publication/domain/usecases/get_works_by_topic.dart';
import '../../../publication/providers/publication_providers.dart';
import 'home_dashboard_state.dart';

/// Logic dashboard của Home (FR 4.2): 6 chỉ số + biểu đồ xu hướng theo năm +
/// danh sách publication để mở Publication Detail.
///
/// Dùng lại `BuildResearchDashboard` — cùng một phép gộp trên mẫu works, không
/// viết lại công thức KPI lần thứ hai.
class HomeDashboardViewModel extends Notifier<HomeDashboardState> {
  /// Mẫu 100 bài nhiều trích dẫn nhất: đủ để tính top author/journal mà vẫn
  /// gọn một request.
  static const int _sampleSize = 100;

  /// Số bài hiển thị dưới dashboard cho người dùng tap vào.
  static const int _publicationsShown = 10;

  Topic? _topic;
  int _requestId = 0;

  @override
  HomeDashboardState build() => const HomeDashboardInitial();

  GetWorksByTopic get _getWorksByTopic => ref.read(getWorksByTopicProvider);
  GetTopicTrend get _getTopicTrend => ref.read(getTopicTrendProvider);

  Future<void> loadByTopic(Topic topic) async {
    _topic = topic;
    final requestId = ++_requestId;
    state = HomeDashboardLoading(topic);

    // Hai request độc lập → chạy song song.
    final worksFuture = _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        perPage: _sampleSize,
        sort: 'cited_by_count:desc',
      ),
    );
    final trendFuture = _getTopicTrend(
      GetTopicTrendParams(topicId: topic.shortId),
    );

    final worksResult = await worksFuture;
    final trendResult = await trendFuture;

    // Bỏ qua kết quả của request đã bị thay thế bởi lần chọn topic mới hơn.
    if (requestId != _requestId || !ref.mounted) return;

    // Trend lỗi không đủ để chặn cả dashboard — vẫn còn trend dựng từ mẫu.
    final trend = trendResult.fold((_) => null, (points) => points);

    worksResult.fold(
      (failure) => state = HomeDashboardError(failure.message, topic),
      (paged) {
        if (paged.items.isEmpty) {
          state = HomeDashboardEmpty(topic);
          return;
        }
        final summary = ref.read(buildResearchDashboardProvider)(
          topic: topic,
          worksPage: paged,
        );
        final resolvedTrend = (trend == null || trend.isEmpty)
            ? summary.yearlyTrend
            : trend;
        state = HomeDashboardLoaded(
          summary: summary,
          trend: resolvedTrend,
          publications: paged.items
              .take(_publicationsShown)
              .toList(growable: false),
          trendWarning: (trend == null || trend.isEmpty)
              ? 'Publication trend is estimated from the sample.'
              : null,
        );
      },
    );
  }

  Future<void> retry() async {
    final topic = _topic;
    if (topic != null) await loadByTopic(topic);
  }

  void clear() {
    _requestId++;
    _topic = null;
    state = const HomeDashboardInitial();
  }
}

final homeDashboardViewModelProvider =
    NotifierProvider<HomeDashboardViewModel, HomeDashboardState>(
  HomeDashboardViewModel.new,
);
