import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../keywords/domain/entities/research_dashboard_summary.dart';
import '../../../publication/data/datasources/publication_remote_datasource.dart';
import '../../../publication/domain/entities/keyword.dart';
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
  PublicationRemoteDatasource get _datasource =>
      ref.read(publicationRemoteDatasourceProvider);

  Future<void> loadByTopic(Topic topic) async {
    _topic = topic;
    final requestId = ++_requestId;
    state = HomeDashboardLoading(topic);

    // Works + trend + top keywords (group_by) chạy song song — 3 request,
    // tránh phụ thuộc field `keywords` trên từng work (thường trống → TC6/TC7).
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

    // Keywords group_by sau works (tránh 429 khi 3 request cùng lúc).
    var keywordGroups = <({Keyword keyword, int count})>[];
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      keywordGroups = await _datasource.getKeywordsByTopic(
        topicId: topic.shortId,
        limit: 8,
      );
    } catch (_) {
      try {
        await Future<void>.delayed(const Duration(seconds: 2));
        keywordGroups = await _datasource.getKeywordsByTopic(
          topicId: topic.shortId,
          limit: 8,
        );
      } catch (_) {
        keywordGroups = const [];
      }
    }

    if (requestId != _requestId || !ref.mounted) return;

    final trend = trendResult.fold((_) => null, (points) => points);

    worksResult.fold(
      (failure) => state = HomeDashboardError(failure.message, topic),
      (paged) {
        if (paged.items.isEmpty) {
          state = HomeDashboardEmpty(topic);
          return;
        }
        var summary = ref.read(buildResearchDashboardProvider)(
          topic: topic,
          worksPage: paged,
        );
        if (keywordGroups.isNotEmpty) {
          summary = summary.copyWith(
            topKeywords: [
              for (final g in keywordGroups)
                RankedResearchItem(
                  name: g.keyword.displayName,
                  count: g.count,
                  keyword: g.keyword,
                ),
            ],
          );
        }
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
