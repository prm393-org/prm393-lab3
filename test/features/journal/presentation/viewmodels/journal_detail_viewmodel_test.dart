import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_detail_state.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_detail_viewmodel.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/journal_summary.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';
import 'package:journal_trend_analyzer/features/shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import 'package:journal_trend_analyzer/firebase/analytics_service.dart';
import 'package:journal_trend_analyzer/firebase/firebase_providers.dart';

import '../../../../helpers/fake_publication_repository.dart';

void main() {
  const journal = JournalSummary(
    id: 'https://openalex.org/S1',
    displayName: 'IEEE Access',
    publicationCount: 40,
    citationCount: 400,
  );
  const topic = Topic(
    id: 'https://openalex.org/T1',
    displayName: 'Cybersecurity',
  );
  const firstWork = Work(
    id: 'https://openalex.org/W1',
    title: 'First work',
    publicationYear: 2024,
    citedByCount: 20,
    authors: [],
    isOpenAccess: false,
  );
  const secondWork = Work(
    id: 'https://openalex.org/W2',
    title: 'Second work',
    publicationYear: 2023,
    citedByCount: 10,
    authors: [],
    isOpenAccess: false,
  );

  late FakePublicationRepository repository;
  late ProviderContainer container;
  late List<(String, Map<String, Object>?)> events;

  setUp(() {
    repository = FakePublicationRepository()
      ..journalResult = const Right(journal)
      ..worksByJournalResults.add(
        const Right(Paged(items: [firstWork], total: 40, page: 1, perPage: 20)),
      );
    events = [];
    container = ProviderContainer(
      overrides: [
        publicationRepositoryProvider.overrideWithValue(repository),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService.forTesting((name, parameters) async {
            events.add((name, parameters));
          }),
        ),
      ],
    );
    container.read(selectedTopicProvider.notifier).select(topic);
  });

  tearDown(() => container.dispose());

  test(
    'loads with preview, resolves metadata and related publications',
    () async {
      final viewModel = container.read(journalDetailViewModelProvider.notifier);
      final load = viewModel.load(journalId: 'S1', preview: journal);
      final loading = container.read(journalDetailViewModelProvider);
      expect(loading, isA<JournalDetailLoading>());
      expect((loading as JournalDetailLoading).preview, journal);
      await load;

      final loaded =
          container.read(journalDetailViewModelProvider) as JournalDetailLoaded;
      expect(loaded.journal, journal);
      expect(loaded.works, [firstWork]);
      expect(loaded.hasMore, isTrue);
    },
  );

  test('deep link loads without preview', () async {
    final viewModel = container.read(journalDetailViewModelProvider.notifier);
    final load = viewModel.load(journalId: 'S1');
    expect(
      (container.read(journalDetailViewModelProvider) as JournalDetailLoading)
          .preview,
      isNull,
    );
    await load;
    expect(
      container.read(journalDetailViewModelProvider),
      isA<JournalDetailLoaded>(),
    );
  });

  test('ignores route preview data for a different source ID', () async {
    const wrongPreview = JournalSummary(
      id: 'https://openalex.org/S2',
      displayName: 'Wrong journal',
      publicationCount: 1,
      citationCount: 1,
    );
    final viewModel = container.read(journalDetailViewModelProvider.notifier);
    final load = viewModel.load(journalId: 'S1', preview: wrongPreview);
    expect(
      (container.read(journalDetailViewModelProvider) as JournalDetailLoading)
          .preview,
      isNull,
    );
    await load;
    final state =
        container.read(journalDetailViewModelProvider) as JournalDetailLoaded;
    expect(state.journal.id, journal.id);
  });

  test('metadata failure without preview is a full error', () async {
    repository.journalResult = const Left(ServerFailure('Metadata failed'));
    await container
        .read(journalDetailViewModelProvider.notifier)
        .load(journalId: 'S1');
    expect(
      container.read(journalDetailViewModelProvider),
      isA<JournalDetailError>(),
    );
  });

  test('related-publications failure keeps resolved journal visible', () async {
    repository.worksByJournalResults
      ..clear()
      ..add(const Left(NetworkFailure('Works failed')));
    await container
        .read(journalDetailViewModelProvider.notifier)
        .load(journalId: 'S1');
    final state =
        container.read(journalDetailViewModelProvider) as JournalDetailLoaded;
    expect(state.journal, journal);
    expect(state.works, isEmpty);
    expect(state.publicationsError, 'Works failed');
  });

  test('load more appends and deduplicates publications', () async {
    repository.worksByJournalResults.add(
      const Right(
        Paged(items: [firstWork, secondWork], total: 40, page: 2, perPage: 20),
      ),
    );
    final viewModel = container.read(journalDetailViewModelProvider.notifier);
    await viewModel.load(journalId: 'S1');
    await viewModel.loadMore();

    final state =
        container.read(journalDetailViewModelProvider) as JournalDetailLoaded;
    expect(state.works, [firstWork, secondWork]);
    expect(repository.lastWorksPage, 2);
  });

  test('load-more failure preserves works and retry succeeds', () async {
    repository.worksByJournalResults
      ..add(const Left(ServerFailure('Next page failed')))
      ..add(
        const Right(
          Paged(items: [secondWork], total: 40, page: 2, perPage: 20),
        ),
      );
    final viewModel = container.read(journalDetailViewModelProvider.notifier);
    await viewModel.load(journalId: 'S1');
    await viewModel.loadMore();
    var state =
        container.read(journalDetailViewModelProvider) as JournalDetailLoaded;
    expect(state.works, [firstWork]);
    expect(state.loadMoreError, 'Next page failed');

    await viewModel.retryLoadMore();
    state =
        container.read(journalDetailViewModelProvider) as JournalDetailLoaded;
    expect(state.works, [firstWork, secondWork]);
    expect(state.loadMoreError, isNull);
  });

  test('maps all related-publication sort modes to OpenAlex sorting', () async {
    final viewModel = container.read(journalDetailViewModelProvider.notifier);
    await viewModel.load(journalId: 'S1');

    await viewModel.setSort(RelatedPublicationSort.newest);
    expect(repository.lastWorksSort, 'publication_date:desc');
    await viewModel.setSort(RelatedPublicationSort.oldest);
    expect(repository.lastWorksSort, 'publication_date:asc');
    await viewModel.setSort(RelatedPublicationSort.mostCited);
    expect(repository.lastWorksSort, 'cited_by_count:desc');
  });

  test('logs view_journal once across rebuild-equivalent actions', () async {
    final viewModel = container.read(journalDetailViewModelProvider.notifier);
    await viewModel.load(journalId: 'S1', preview: journal);
    await viewModel.loadMore();
    await viewModel.setSort(RelatedPublicationSort.newest);
    await viewModel.retry();

    expect(events, hasLength(1));
    expect(events.single.$1, 'view_journal');
    expect(events.single.$2?['journal_name'], 'IEEE Access');
    expect(events.single.$2?['journal_id'], 'S1');
  });
}
