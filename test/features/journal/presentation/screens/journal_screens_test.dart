import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/screens/journal_detail_screen.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/screens/journal_screen.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_detail_state.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_detail_viewmodel.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_state.dart';
import 'package:journal_trend_analyzer/features/journal/presentation/viewmodels/journal_viewmodel.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/journal_summary.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';

void main() {
  for (final width in [360.0, 768.0]) {
    testWidgets('Journals renders responsive loaded UI at ${width.toInt()}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalViewModelProvider.overrideWith(_FixtureJournalViewModel.new),
          ],
          child: const MaterialApp(home: Scaffold(body: JournalScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journals_screen')), findsOneWidget);
      expect(find.text('JOURNAL CONTRIBUTION'), findsOneWidget);
      expect(find.byKey(const Key('journal_sort')), findsOneWidget);
      expect(find.byKey(const Key('journal_card_S1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Journal Detail renders responsive metrics at ${width.toInt()}px',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              journalDetailViewModelProvider.overrideWith(
                _FixtureDetailViewModel.new,
              ),
            ],
            child: const MaterialApp(
              home: JournalDetailScreen(journalId: 'S1', preview: _journal),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('journal_detail_screen')), findsOneWidget);
        expect(find.byKey(const Key('journal_identity_card')), findsOneWidget);
        expect(
          find.byKey(const Key('journal_total_publications')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('journal_total_citations')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('journal_average_citations')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('related_publication_W1')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final fixture in const <(JournalState, String)>[
    (JournalInitial(), 'Choose a research topic'),
    (JournalLoading(_topic), 'Topic: Cybersecurity'),
    (JournalEmpty(_topic), 'No journals found'),
    (JournalError('Journal request failed', _topic), 'Journal request failed'),
  ]) {
    testWidgets('Journals renders ${fixture.$1.runtimeType}', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalViewModelProvider.overrideWith(
              () => _StateJournalViewModel(fixture.$1),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: JournalScreen())),
        ),
      );
      await tester.pump();

      expect(find.text(fixture.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final fixture in <(JournalDetailState, String)>[
    const (
      JournalDetailError(message: 'Metadata request failed'),
      'Metadata request failed',
    ),
    const (
      JournalDetailLoaded(
        journal: _journal,
        works: [],
        totalWorks: 0,
        hasMore: false,
      ),
      'No related publications found for this journal and topic.',
    ),
    const (
      JournalDetailLoaded(
        journal: _journal,
        works: [],
        totalWorks: 0,
        hasMore: false,
        publicationsError: 'Publication request failed',
      ),
      'Publication request failed',
    ),
  ]) {
    testWidgets('Journal Detail renders ${fixture.$1.runtimeType}', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalDetailViewModelProvider.overrideWith(
              () => _StateDetailViewModel(fixture.$1),
            ),
          ],
          child: const MaterialApp(home: JournalDetailScreen(journalId: 'S1')),
        ),
      );
      await tester.pump();

      expect(find.text(fixture.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('journal card navigates with the exact source ID route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/journal',
      routes: [
        GoRoute(
          path: '/journal',
          builder: (context, state) => const Scaffold(body: JournalScreen()),
          routes: [
            GoRoute(
              path: 'journal-detail/:journalId',
              builder: (_, state) => Scaffold(
                body: Text('journal:${state.pathParameters['journalId']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalViewModelProvider.overrideWith(_FixtureJournalViewModel.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal_card_S1')));
    await tester.pumpAndSettle();

    expect(find.text('journal:S1'), findsOneWidget);
  });

  testWidgets('related publication opens the exact nested route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/journal/journal-detail/S1',
      routes: [
        GoRoute(
          path: '/journal/journal-detail/:journalId',
          builder: (_, state) => JournalDetailScreen(
            journalId: state.pathParameters['journalId']!,
            preview: _journal,
          ),
          routes: [
            GoRoute(
              path: 'publication/:workId',
              builder: (_, state) => Scaffold(
                body: Text('work:${state.pathParameters['workId']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalDetailViewModelProvider.overrideWith(
            _FixtureDetailViewModel.new,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('related_publication_W1')));
    await tester.pumpAndSettle();

    expect(find.text('work:W1'), findsOneWidget);
  });
}

class _FixtureJournalViewModel extends JournalViewModel {
  @override
  JournalState build() => const JournalLoaded(
    topic: _topic,
    journals: [_journal, _secondJournal],
    maxDisplayed: 10,
  );
}

class _StateJournalViewModel extends JournalViewModel {
  final JournalState fixture;

  _StateJournalViewModel(this.fixture);

  @override
  JournalState build() => fixture;
}

class _FixtureDetailViewModel extends JournalDetailViewModel {
  @override
  JournalDetailState build() => const JournalDetailLoaded(
    journal: _journal,
    works: [_work],
    totalWorks: 21,
    hasMore: true,
  );

  @override
  Future<void> load({
    required String journalId,
    JournalSummary? preview,
  }) async {}
}

class _StateDetailViewModel extends JournalDetailViewModel {
  final JournalDetailState fixture;

  _StateDetailViewModel(this.fixture);

  @override
  JournalDetailState build() => fixture;

  @override
  Future<void> load({
    required String journalId,
    JournalSummary? preview,
  }) async {}
}

const _topic = Topic(
  id: 'https://openalex.org/T1',
  displayName: 'Cybersecurity',
);

const _journal = JournalSummary(
  id: 'https://openalex.org/S1',
  displayName: 'IEEE Access with a deliberately long journal title',
  issn: '2169-3536',
  publisher: 'IEEE',
  publicationCount: 14203,
  citationCount: 830000,
);

const _secondJournal = JournalSummary(
  id: 'https://openalex.org/S2',
  displayName: 'Sensors',
  publicationCount: 11542,
  citationCount: 601220,
);

const _work = Work(
  id: 'https://openalex.org/W1',
  title: 'Progress and challenges in magnetic confinement fusion',
  publicationYear: 2023,
  type: 'article',
  citedByCount: 8301,
  authors: [
    Author(displayName: 'Chen, L.'),
    Author(displayName: 'Smith, J.'),
    Author(displayName: 'Nguyen, T.'),
  ],
  isOpenAccess: true,
);
