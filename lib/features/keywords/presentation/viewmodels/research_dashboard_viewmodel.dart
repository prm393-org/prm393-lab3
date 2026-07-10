import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ResearchDashboardState build() => const ResearchDashboardInitial();

  GetWorksByTopic get _getWorksByTopic => ref.read(getWorksByTopicProvider);
  BuildResearchDashboard get _buildResearchDashboard =>
      ref.read(buildResearchDashboardProvider);

  Future<void> loadByTopic(Topic topic) async {
    _topic = topic;
    final requestId = ++_requestId;
    state = ResearchDashboardLoading(topic);

    final result = await _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        perPage: _sampleSize,
        sort: 'cited_by_count:desc',
      ),
    );

    // Bỏ qua kết quả của request đã bị thay thế bởi lần load mới hơn.
    if (requestId != _requestId || !ref.mounted) return;

    result.fold(
      (failure) => state = ResearchDashboardError(failure.message, topic),
      (paged) {
        if (paged.items.isEmpty) {
          state = ResearchDashboardEmpty(topic);
          return;
        }
        state = ResearchDashboardLoaded(
          _buildResearchDashboard(topic: topic, worksPage: paged),
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
    state = const ResearchDashboardInitial();
  }
}

final researchDashboardViewModelProvider =
    NotifierProvider<ResearchDashboardViewModel, ResearchDashboardState>(
  ResearchDashboardViewModel.new,
);
