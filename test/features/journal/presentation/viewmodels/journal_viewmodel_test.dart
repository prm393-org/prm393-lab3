import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_state.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_viewmodel.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/journal_summary.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';

import '../../../../helpers/fake_publication_repository.dart';

void main() {
  const topic = Topic(
    id: 'https://openalex.org/T1',
    displayName: 'Cybersecurity',
  );
  const journals = [
    JournalSummary(
      id: 'https://openalex.org/S2',
      displayName: 'Beta',
      publicationCount: 20,
      citationCount: 200,
    ),
    JournalSummary(
      id: 'https://openalex.org/S1',
      displayName: 'Alpha',
      publicationCount: 20,
      citationCount: 100,
    ),
    JournalSummary(
      id: 'https://openalex.org/S3',
      displayName: 'Gamma',
      publicationCount: 10,
      citationCount: 300,
    ),
  ];

  late FakePublicationRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakePublicationRepository()
      ..journalsResult = const Right(journals);
    container = ProviderContainer(
      overrides: [
        publicationRepositoryProvider.overrideWithValue(repository),
        journalDisplayLimitProvider.overrideWithValue(0),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('starts with no-topic initial state', () {
    expect(container.read(journalViewModelProvider), isA<JournalInitial>());
  });

  test('maps loading to loaded and uses fallback display limit', () async {
    final viewModel = container.read(journalViewModelProvider.notifier);
    final load = viewModel.loadByTopic(topic);
    expect(container.read(journalViewModelProvider), isA<JournalLoading>());
    await load;

    final state = container.read(journalViewModelProvider) as JournalLoaded;
    expect(state.journals, journals);
    expect(state.sort, JournalSort.publications);
    expect(repository.lastJournalLimit, 10);
  });

  test('applies a configured display limit', () async {
    final limitedContainer = ProviderContainer(
      overrides: [
        publicationRepositoryProvider.overrideWithValue(repository),
        journalDisplayLimitProvider.overrideWithValue(2),
      ],
    );
    addTearDown(limitedContainer.dispose);

    await limitedContainer
        .read(journalViewModelProvider.notifier)
        .loadByTopic(topic);
    final state =
        limitedContainer.read(journalViewModelProvider) as JournalLoaded;
    expect(state.journals, hasLength(2));
    expect(repository.lastJournalLimit, 2);
  });

  test('maps loading failure to error', () async {
    repository.journalsResult = const Left(NetworkFailure());
    await container.read(journalViewModelProvider.notifier).loadByTopic(topic);
    expect(container.read(journalViewModelProvider), isA<JournalError>());
  });

  test(
    'refresh preserves loaded content and exposes non-blocking failure',
    () async {
      final viewModel = container.read(journalViewModelProvider.notifier);
      await viewModel.loadByTopic(topic);
      repository.journalsResult = const Left(ServerFailure('Refresh failed'));

      final refresh = viewModel.refresh();
      final refreshing =
          container.read(journalViewModelProvider) as JournalLoaded;
      expect(refreshing.journals, journals);
      expect(refreshing.isRefreshing, isTrue);
      await refresh;

      final failed = container.read(journalViewModelProvider) as JournalLoaded;
      expect(failed.journals, journals);
      expect(failed.isRefreshing, isFalse);
      expect(failed.refreshError, 'Refresh failed');
    },
  );

  test('sorts all metrics descending with deterministic ties', () async {
    final viewModel = container.read(journalViewModelProvider.notifier);
    await viewModel.loadByTopic(topic);

    var state = container.read(journalViewModelProvider) as JournalLoaded;
    expect(state.sortedJournals.map((item) => item.displayName), [
      'Alpha',
      'Beta',
      'Gamma',
    ]);

    viewModel.setSort(JournalSort.citations);
    state = container.read(journalViewModelProvider) as JournalLoaded;
    expect(state.sortedJournals.map((item) => item.displayName), [
      'Gamma',
      'Beta',
      'Alpha',
    ]);

    viewModel.setSort(JournalSort.averageCitations);
    state = container.read(journalViewModelProvider) as JournalLoaded;
    expect(state.sortedJournals.map((item) => item.displayName), [
      'Gamma',
      'Beta',
      'Alpha',
    ]);
  });
}
