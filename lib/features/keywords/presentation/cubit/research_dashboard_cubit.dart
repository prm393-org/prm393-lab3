import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/get_works_by_topic.dart';
import '../../domain/usecases/build_research_dashboard.dart';
import 'research_dashboard_state.dart';

class ResearchDashboardCubit extends Cubit<ResearchDashboardState> {
  final GetWorksByTopic _getWorksByTopic;
  final BuildResearchDashboard _buildResearchDashboard;

  ResearchDashboardCubit(this._getWorksByTopic, this._buildResearchDashboard)
    : super(const ResearchDashboardInitial());

  static const int _sampleSize = 100;

  Topic? _topic;
  int _requestId = 0;

  Future<void> loadByTopic(Topic topic) async {
    _topic = topic;
    final requestId = ++_requestId;
    emit(ResearchDashboardLoading(topic));

    final result = await _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        perPage: _sampleSize,
        sort: 'cited_by_count:desc',
      ),
    );

    if (requestId != _requestId || isClosed) return;

    result.fold(
      (failure) => emit(ResearchDashboardError(failure.message, topic)),
      (paged) {
        if (paged.items.isEmpty) {
          emit(ResearchDashboardEmpty(topic));
          return;
        }
        emit(
          ResearchDashboardLoaded(
            _buildResearchDashboard(topic: topic, worksPage: paged),
          ),
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
    emit(const ResearchDashboardInitial());
  }
}
