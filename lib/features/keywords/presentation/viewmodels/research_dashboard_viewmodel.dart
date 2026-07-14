import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../../home/presentation/viewmodels/home_dashboard_state.dart';
import '../../../home/presentation/viewmodels/home_dashboard_viewmodel.dart';
import '../../domain/entities/research_dashboard_summary.dart';
import '../../../publication/data/datasources/publication_remote_datasource.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/get_works_by_topic.dart';
import '../../../publication/providers/publication_providers.dart';
import '../../domain/usecases/build_research_dashboard.dart';
import 'research_dashboard_state.dart';

class ResearchDashboardViewModel extends Notifier<ResearchDashboardState> {
  static const int _sampleSize = 100;

  Topic? _topic;
  int _requestId = 0;

  @override
  ResearchDashboardState build() {
    ref.listen(homeDashboardViewModelProvider, (_, next) {
      final topic = _topic;
      if (topic == null) return;
      if (next is! HomeDashboardLoaded) return;
      if (next.summary.topic.id != topic.id) return;

      final current = state;
      final shouldAdopt = current is ResearchDashboardLoading ||
          current is ResearchDashboardInitial ||
          (current is ResearchDashboardLoaded &&
              current.summary.topKeywords.isEmpty &&
              next.summary.topKeywords.isNotEmpty);
      if (shouldAdopt) {
        // ignore: discarded_futures
        _publishSummary(next.summary, requestId: _requestId);
      }
    });
    return const ResearchDashboardInitial();
  }

  GetWorksByTopic get _getWorksByTopic => ref.read(getWorksByTopicProvider);
  BuildResearchDashboard get _buildResearchDashboard =>
      ref.read(buildResearchDashboardProvider);
  PublicationRemoteDatasource get _datasource =>
      ref.read(publicationRemoteDatasourceProvider);

  Future<void> loadByTopic(Topic topic) async {
    _topic = topic;
    final requestId = ++_requestId;
    state = ResearchDashboardLoading(topic);

    final home = ref.read(homeDashboardViewModelProvider);
    if (home is HomeDashboardLoaded && home.summary.topic.id == topic.id) {
      await _publishSummary(home.summary, requestId: requestId);
      return;
    }
    if (home is HomeDashboardLoading && home.topic.id == topic.id) {
      return;
    }

    final result = await _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        perPage: _sampleSize,
        sort: 'cited_by_count:desc',
      ),
    );

    if (requestId != _requestId || !ref.mounted) return;

    final remoteConfig = ref.read(remoteConfigServiceProvider);
    final journalLimit = remoteConfig.maxJournalsDisplayed > 0
        ? remoteConfig.maxJournalsDisplayed
        : 5;
    final keywordLimit = remoteConfig.maxKeywordsDisplayed > 0
        ? remoteConfig.maxKeywordsDisplayed
        : 8;

    await result.fold(
      (failure) async {
        if (requestId != _requestId || !ref.mounted) return;
        state = ResearchDashboardError(failure.message, topic);
      },
      (paged) async {
        if (paged.items.isEmpty) {
          if (requestId != _requestId || !ref.mounted) return;
          state = ResearchDashboardEmpty(topic);
          return;
        }
        final summary = _buildResearchDashboard(
          topic: topic,
          worksPage: paged,
          journalLimit: journalLimit,
          keywordLimit: keywordLimit,
        );
        await _publishSummary(summary, requestId: requestId);
      },
    );
  }

  /// Gắn topKeywords từ `group_by` nếu mẫu works không có keyword.
  Future<void> _publishSummary(
    ResearchDashboardSummary summary, {
    required int requestId,
  }) async {
    var resolved = summary;
    if (resolved.topKeywords.isEmpty) {
      try {
        final remoteConfig = ref.read(remoteConfigServiceProvider);
        final keywordLimit = remoteConfig.maxKeywordsDisplayed > 0
            ? remoteConfig.maxKeywordsDisplayed
            : 8;
        final groups = await _datasource.getKeywordsByTopic(
          topicId: resolved.topic.shortId,
          limit: keywordLimit,
        );
        if (groups.isNotEmpty) {
          resolved = resolved.copyWith(
            topKeywords: [
              for (final g in groups)
                RankedResearchItem(
                  name: g.keyword.displayName,
                  count: g.count,
                  keyword: g.keyword,
                ),
            ],
          );
        }
      } catch (_) {
        // Giữ summary gốc nếu group_by lỗi / 429.
      }
    }
    if (requestId != _requestId || !ref.mounted) return;
    state = ResearchDashboardLoaded(resolved);
  }

  Future<void> retry() async {
    final topic = _topic;
    if (topic != null) await loadByTopic(topic);
  }

  void clear() {
    _requestId++;
    _topic = null;
    state = const ResearchDashboardInitial();
  }
}

final researchDashboardViewModelProvider =
    NotifierProvider<ResearchDashboardViewModel, ResearchDashboardState>(
  ResearchDashboardViewModel.new,
);
