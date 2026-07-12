import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../../publication/domain/entities/journal_summary.dart';
import '../../../publication/domain/entities/work.dart';
import '../../../publication/domain/usecases/get_journal_by_id.dart';
import '../../../publication/domain/usecases/get_works_by_journal.dart';
import '../../../publication/providers/publication_providers.dart';
import '../../../shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import 'journal_detail_state.dart';

class JournalDetailViewModel extends Notifier<JournalDetailState> {
  static const _perPage = 20;

  String? _journalId;
  String? _topicId;
  JournalSummary? _preview;
  int _page = 1;
  int _generation = 0;
  bool _analyticsLogged = false;
  RelatedPublicationSort _sort = RelatedPublicationSort.mostCited;

  @override
  JournalDetailState build() => const JournalDetailInitial();

  GetJournalById get _getJournalById => ref.read(getJournalByIdProvider);
  GetWorksByJournal get _getWorksByJournal =>
      ref.read(getWorksByJournalProvider);

  Future<void> load({
    required String journalId,
    JournalSummary? preview,
  }) async {
    final normalized = _normalizeId(journalId);
    final usablePreview =
        preview != null && _normalizeId(preview.id) == normalized
        ? preview
        : null;
    final isNewJournal = _journalId != normalized;
    if (isNewJournal) {
      _analyticsLogged = false;
      _sort = RelatedPublicationSort.mostCited;
    }
    _journalId = normalized;
    _preview = usablePreview;
    _topicId = ref.read(selectedTopicProvider)?.shortId;
    _page = 1;
    final generation = ++_generation;
    state = JournalDetailLoading(preview: usablePreview);
    if (usablePreview != null && usablePreview.hasValidId) {
      _logOnce(usablePreview);
    }
    await _loadFirstPage(generation: generation, preview: usablePreview);
  }

  Future<void> retry() async {
    final journalId = _journalId;
    if (journalId == null) return;
    final preview = switch (state) {
      JournalDetailLoaded s => s.journal,
      JournalDetailLoading s => s.preview,
      JournalDetailError s => s.preview,
      JournalDetailInitial() => _preview,
    };
    await load(journalId: journalId, preview: preview);
  }

  Future<void> _loadFirstPage({
    required int generation,
    required JournalSummary? preview,
  }) async {
    final journalId = _journalId;
    if (journalId == null) return;
    final metadataFuture = _getJournalById(
      GetJournalByIdParams(journalId: journalId),
    );
    final worksFuture = _getWorksByJournal(
      GetWorksByJournalParams(
        journalId: journalId,
        topicId: _topicId,
        perPage: _perPage,
        sort: _sort.apiValue,
      ),
    );
    final metadataResult = await metadataFuture;
    final worksResult = await worksFuture;
    if (!ref.mounted || generation != _generation) return;

    JournalSummary? resolved;
    String? metadataWarning;
    metadataResult.fold(
      (failure) {
        resolved = preview;
        metadataWarning = failure.message;
      },
      (fresh) {
        resolved = preview == null ? fresh : _mergePreview(preview, fresh);
      },
    );
    final journal = resolved;
    if (journal == null) {
      state = JournalDetailError(
        message: metadataWarning ?? 'Unable to load journal metadata',
      );
      return;
    }
    _logOnce(journal);

    worksResult.fold(
      (failure) {
        state = JournalDetailLoaded(
          journal: journal,
          works: const [],
          totalWorks: 0,
          hasMore: false,
          sort: _sort,
          metadataWarning: metadataWarning,
          publicationsError: failure.message,
        );
      },
      (page) {
        state = JournalDetailLoaded(
          journal: journal,
          works: _deduplicate(page.items),
          totalWorks: page.total,
          hasMore: page.hasMore,
          sort: _sort,
          metadataWarning: metadataWarning,
        );
      },
    );
  }

  JournalSummary _mergePreview(
    JournalSummary preview,
    JournalSummary metadata,
  ) {
    return preview.copyWith(
      displayName: preview.displayName == 'Unknown Source'
          ? metadata.displayName
          : preview.displayName,
      issn: metadata.issn,
      publisher: metadata.publisher,
    );
  }

  Future<void> setSort(
    RelatedPublicationSort sort, {
    bool force = false,
  }) async {
    final current = state;
    if (current is! JournalDetailLoaded || (!force && current.sort == sort)) {
      return;
    }
    _sort = sort;
    _page = 1;
    final generation = ++_generation;
    state = current.copyWith(
      sort: sort,
      isRefreshing: true,
      clearPublicationsError: true,
      clearLoadMoreError: true,
    );
    final result = await _getWorksByJournal(
      GetWorksByJournalParams(
        journalId: _journalId!,
        topicId: _topicId,
        perPage: _perPage,
        sort: sort.apiValue,
      ),
    );
    if (!ref.mounted || generation != _generation) return;
    result.fold(
      (failure) => state = current.copyWith(
        sort: sort,
        isRefreshing: false,
        publicationsError: failure.message,
      ),
      (page) => state = current.copyWith(
        works: _deduplicate(page.items),
        totalWorks: page.total,
        hasMore: page.hasMore,
        sort: sort,
        isRefreshing: false,
        clearPublicationsError: true,
      ),
    );
  }

  Future<void> retryPublications() async {
    final current = state;
    if (current is JournalDetailLoaded) {
      await setSort(current.sort, force: true);
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! JournalDetailLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }
    final nextPage = _page + 1;
    final generation = _generation;
    state = current.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final result = await _getWorksByJournal(
      GetWorksByJournalParams(
        journalId: _journalId!,
        topicId: _topicId,
        page: nextPage,
        perPage: _perPage,
        sort: _sort.apiValue,
      ),
    );
    if (!ref.mounted || generation != _generation) return;
    result.fold(
      (failure) => state = current.copyWith(
        isLoadingMore: false,
        loadMoreError: failure.message,
      ),
      (page) {
        _page = nextPage;
        state = current.copyWith(
          works: _deduplicate([...current.works, ...page.items]),
          totalWorks: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearLoadMoreError: true,
        );
      },
    );
  }

  Future<void> retryLoadMore() => loadMore();

  List<Work> _deduplicate(Iterable<Work> works) {
    final byId = <String, Work>{};
    for (final work in works) {
      if (work.id.isNotEmpty) byId.putIfAbsent(work.id, () => work);
    }
    return byId.values.toList(growable: false);
  }

  void _logOnce(JournalSummary journal) {
    if (_analyticsLogged || !journal.hasValidId) return;
    _analyticsLogged = true;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logViewJournal(
            journalName: journal.displayName,
            journalId: journal.shortId,
          )
          .catchError((_) {}),
    );
  }

  String _normalizeId(String raw) {
    final decoded = Uri.decodeComponent(raw.trim());
    final shortId = decoded.split('/').last;
    return shortId.startsWith('S') ? 'https://openalex.org/$shortId' : decoded;
  }
}

final journalDetailViewModelProvider =
    NotifierProvider.autoDispose<JournalDetailViewModel, JournalDetailState>(
      JournalDetailViewModel.new,
    );
