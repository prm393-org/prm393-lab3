import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/publication_detail_state.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/publication_detail_viewmodel.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';
import 'package:journal_trend_analyzer/firebase/analytics_service.dart';
import 'package:journal_trend_analyzer/firebase/firebase_providers.dart';

import '../../../../helpers/fake_publication_repository.dart';

void main() {
  const work = Work(
    id: 'https://openalex.org/W1',
    title: 'Attention Is All You Need',
    publicationYear: 2017,
    citedByCount: 300,
    authors: [],
    isOpenAccess: true,
  );
  const undatedWork = Work(
    id: 'https://openalex.org/W2',
    title: 'Preprint without a year',
    citedByCount: 0,
    authors: [],
    isOpenAccess: false,
  );

  late FakePublicationRepository repository;
  late ProviderContainer container;
  late List<(String, Map<String, Object>?)> events;

  setUp(() {
    repository = FakePublicationRepository()..workByIdResult = const Right(work);
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
  });

  tearDown(() => container.dispose());

  test('logs view_publication with title and year', () async {
    await container
        .read(publicationDetailViewModelProvider.notifier)
        .load(workId: 'W1', preview: work);

    expect(
      container.read(publicationDetailViewModelProvider),
      isA<PublicationDetailLoaded>(),
    );
    expect(events, hasLength(1));
    expect(events.single.$1, 'view_publication');
    expect(events.single.$2?['publication_title'], 'Attention Is All You Need');
    expect(events.single.$2?['publication_year'], 2017);
  });

  test('deep link without preview still logs once the work resolves', () async {
    await container
        .read(publicationDetailViewModelProvider.notifier)
        .load(workId: 'W1');

    expect(events.single.$1, 'view_publication');
    expect(events.single.$2?['publication_title'], 'Attention Is All You Need');
  });

  test('retry does not double-count the same publication view', () async {
    final viewModel = container.read(
      publicationDetailViewModelProvider.notifier,
    );
    await viewModel.load(workId: 'W1', preview: work);
    await viewModel.retry();

    expect(events, hasLength(1));
  });

  test('missing publication year is sent as 0, not null', () async {
    repository.workByIdResult = const Right(undatedWork);
    await container
        .read(publicationDetailViewModelProvider.notifier)
        .load(workId: 'W2');

    expect(events.single.$2?['publication_year'], 0);
  });

  test('a failed fetch with a preview still records the view', () async {
    repository.workByIdResult = const Left(ServerFailure('Boom'));
    await container
        .read(publicationDetailViewModelProvider.notifier)
        .load(workId: 'W1', preview: work);

    expect(
      container.read(publicationDetailViewModelProvider),
      isA<PublicationDetailError>(),
    );
    expect(events, hasLength(1));
  });
}
