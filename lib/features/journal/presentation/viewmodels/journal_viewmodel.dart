import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/get_journals_by_topic.dart';
import '../../../publication/providers/publication_providers.dart';
import 'journal_state.dart';

final journalDisplayLimitProvider = Provider<int>((ref) {
  final configured = ref
      .watch(remoteConfigServiceProvider)
      .maxJournalsDisplayed;
  return configured > 0 ? configured : 10;
});

class JournalViewModel extends Notifier<JournalState> {
  Topic? _topic;
  JournalSort _sort = JournalSort.publications;
  int _requestGeneration = 0;

  @override
  JournalState build() => const JournalInitial();

  GetJournalsByTopic get _getJournalsByTopic =>
      ref.read(getJournalsByTopicProvider);

  int get _displayLimit => ref.read(journalDisplayLimitProvider);

  Future<void> loadByTopic(Topic topic) async {
    final isNewTopic = _topic?.id != topic.id;
    _topic = topic;
    if (isNewTopic) _sort = JournalSort.publications;
    final generation = ++_requestGeneration;
    state = JournalLoading(topic);
    await _load(topic: topic, generation: generation, preserve: null);
  }

  Future<void> refresh() async {
    final topic = _topic;
    if (topic == null) return;
    final existing = state is JournalLoaded ? state as JournalLoaded : null;
    final generation = ++_requestGeneration;
    if (existing != null) {
      state = existing.copyWith(isRefreshing: true, clearRefreshError: true);
    } else {
      state = JournalLoading(topic);
    }
    await _load(topic: topic, generation: generation, preserve: existing);
  }

  Future<void> _load({
    required Topic topic,
    required int generation,
    required JournalLoaded? preserve,
  }) async {
    final limit = _displayLimit > 0 ? _displayLimit : 10;
    final result = await _getJournalsByTopic(
      GetJournalsByTopicParams(topicId: topic.shortId, limit: limit),
    );
    if (!ref.mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = preserve == null
            ? JournalError(failure.message, topic)
            : preserve.copyWith(
                isRefreshing: false,
                refreshError: failure.message,
              );
      },
      (journals) {
        final limited = journals.take(limit).toList(growable: false);
        state = limited.isEmpty
            ? JournalEmpty(topic)
            : JournalLoaded(
                topic: topic,
                journals: limited,
                maxDisplayed: limit,
                sort: _sort,
              );
      },
    );
  }

  void setSort(JournalSort sort) {
    _sort = sort;
    final current = state;
    if (current is JournalLoaded && current.sort != sort) {
      state = current.copyWith(sort: sort);
    }
  }

  void clear() {
    _requestGeneration++;
    _topic = null;
    _sort = JournalSort.publications;
    state = const JournalInitial();
  }
}

final journalViewModelProvider =
    NotifierProvider<JournalViewModel, JournalState>(JournalViewModel.new);
