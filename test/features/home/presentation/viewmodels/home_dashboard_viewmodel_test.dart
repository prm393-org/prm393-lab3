import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/features/home/presentation/viewmodels/home_dashboard_state.dart';
import 'package:journal_trend_analyzer/features/home/presentation/viewmodels/home_dashboard_viewmodel.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';

import '../../../../helpers/fake_publication_repository.dart';

void main() {
  const topic = Topic(
    id: 'https://openalex.org/T1',
    displayName: 'Machine Learning',
  );

  const mostCited = Work(
    id: 'https://openalex.org/W1',
    title: 'Attention Is All You Need',
    publicationYear: 2021,
    citedByCount: 300,
    authors: [Author(id: 'A1', displayName: 'Ashish Vaswani')],
    sourceName: 'NeurIPS',
    isOpenAccess: true,
  );
  const second = Work(
    id: 'https://openalex.org/W2',
    title: 'Deep Residual Learning',
    publicationYear: 2021,
    citedByCount: 100,
    authors: [Author(id: 'A1', displayName: 'Ashish Vaswani')],
    sourceName: 'NeurIPS',
    isOpenAccess: false,
  );
  const third = Work(
    id: 'https://openalex.org/W3',
    title: 'BERT',
    publicationYear: 2019,
    citedByCount: 50,
    authors: [Author(id: 'A2', displayName: 'Jacob Devlin')],
    sourceName: 'NAACL',
    isOpenAccess: false,
  );

  const sample = Paged<Work>(
    items: [mostCited, second, third],
    total: 1200,
    page: 1,
    perPage: 100,
  );

  late FakePublicationRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakePublicationRepository()
      ..worksByTopicResult = const Right(sample);
    container = ProviderContainer(
      overrides: [publicationRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  HomeDashboardState read() => container.read(homeDashboardViewModelProvider);

  test('computes the six KPIs required by FR 4.2', () async {
    await container
        .read(homeDashboardViewModelProvider.notifier)
        .loadByTopic(topic);

    final summary = (read() as HomeDashboardLoaded).summary;

    expect(summary.totalPublications, 1200);
    expect(summary.averageCitations, closeTo(150, 0.01)); // (300+100+50)/3
    expect(summary.mostActiveYear, 2021);
    expect(summary.topAuthor?.name, 'Ashish Vaswani');
    expect(summary.topAuthor?.count, 2);
    expect(summary.topJournal?.name, 'NeurIPS');
    expect(summary.topJournal?.count, 2);
    expect(summary.mostInfluentialPublication, mostCited);
  });

  test('exposes publications to tap through to Publication Detail', () async {
    await container
        .read(homeDashboardViewModelProvider.notifier)
        .loadByTopic(topic);

    final loaded = read() as HomeDashboardLoaded;
    expect(loaded.publications, [mostCited, second, third]);
    expect(loaded.topic, topic);
  });

  test('prefers the OpenAlex group_by trend over the sampled one', () async {
    repository.topicTrendResult = const Right([
      TrendPoint(year: 2019, count: 40),
      TrendPoint(year: 2020, count: 80),
      TrendPoint(year: 2021, count: 120),
    ]);

    await container
        .read(homeDashboardViewModelProvider.notifier)
        .loadByTopic(topic);

    final loaded = read() as HomeDashboardLoaded;
    expect(loaded.trend.map((p) => p.count), [40, 80, 120]);
    expect(loaded.trendWarning, isNull);
  });

  test('falls back to the sampled trend and warns when group_by fails', () async {
    repository.topicTrendResult = const Left(ServerFailure('Trend failed'));

    await container
        .read(homeDashboardViewModelProvider.notifier)
        .loadByTopic(topic);

    final loaded = read() as HomeDashboardLoaded;
    // Dựng từ mẫu: 2019 có 1 bài, 2021 có 2 bài.
    expect(loaded.trend, const [
      TrendPoint(year: 2019, count: 1),
      TrendPoint(year: 2021, count: 2),
    ]);
    expect(loaded.trendWarning, isNotNull);
  });

  test('empty sample yields the empty state, not a zeroed dashboard', () async {
    repository.worksByTopicResult = const Right(
      Paged(items: [], total: 0, page: 1, perPage: 100),
    );

    await container
        .read(homeDashboardViewModelProvider.notifier)
        .loadByTopic(topic);

    expect(read(), isA<HomeDashboardEmpty>());
  });

  test('works failure surfaces an error that retry can recover from', () async {
    repository.worksByTopicResult = const Left(NetworkFailure('Offline'));

    final viewModel = container.read(homeDashboardViewModelProvider.notifier);
    await viewModel.loadByTopic(topic);
    expect((read() as HomeDashboardError).message, 'Offline');

    repository.worksByTopicResult = const Right(sample);
    await viewModel.retry();
    expect(read(), isA<HomeDashboardLoaded>());
  });

  test('requests the top-cited sample for the selected topic', () async {
    await container
        .read(homeDashboardViewModelProvider.notifier)
        .loadByTopic(topic);

    expect(repository.lastTopicId, 'T1');
    expect(repository.lastWorksSort, 'cited_by_count:desc');
  });

  test('clear() drops the dashboard back to initial', () async {
    final viewModel = container.read(homeDashboardViewModelProvider.notifier);
    await viewModel.loadByTopic(topic);
    viewModel.clear();

    expect(read(), isA<HomeDashboardInitial>());
  });
}
