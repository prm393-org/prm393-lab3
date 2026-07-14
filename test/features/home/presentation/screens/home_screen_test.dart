import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:journal_trend_analyzer/core/providers/core_providers.dart';
import 'package:journal_trend_analyzer/features/home/presentation/screens/home_screen.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';
import 'package:journal_trend_analyzer/features/shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fake_publication_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  const sameJournal = Work(
    id: 'https://openalex.org/W2',
    title: 'Transformers for Vision',
    publicationYear: 2021,
    citedByCount: 100,
    authors: [Author(id: 'A1', displayName: 'Ashish Vaswani')],
    sourceName: 'NeurIPS',
    isOpenAccess: false,
  );
  const other = Work(
    id: 'https://openalex.org/W3',
    title: 'Deep Residual Learning',
    publicationYear: 2019,
    citedByCount: 50,
    authors: [Author(id: 'A2', displayName: 'Kaiming He')],
    sourceName: 'CVPR',
    isOpenAccess: false,
  );

  late SharedPreferences prefs;
  late FakePublicationRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = FakePublicationRepository()
      ..worksByTopicResult = const Right(
        Paged(
          items: [mostCited, sameJournal, other],
          total: 1200,
          page: 1,
          perPage: 100,
        ),
      );
  });

  Future<ProviderContainer> pumpHome(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        publicationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Topic đã chọn sẵn → Home phải tự dựng dashboard khi mở.
    container.read(selectedTopicProvider.notifier).select(topic);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the six FR 4.2 KPIs for the selected topic', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpHome(tester);

    expect(find.byKey(WidgetKeys.homeKpiTotalPublications), findsOneWidget);
    expect(find.byKey(WidgetKeys.homeKpiAverageCitations), findsOneWidget);
    expect(find.byKey(WidgetKeys.homeKpiMostActiveYear), findsOneWidget);
    expect(find.byKey(WidgetKeys.homeKpiTopAuthor), findsOneWidget);
    expect(find.byKey(WidgetKeys.homeKpiTopJournal), findsOneWidget);
    expect(find.byKey(WidgetKeys.homeKpiMostInfluential), findsOneWidget);

    // Giá trị thật, không phải placeholder. Tìm trong đúng thẻ KPI vì các tên
    // này cũng xuất hiện ở danh sách publication bên dưới.
    Finder inKpi(Key card, String text) => find.descendant(
      of: find.byKey(card),
      matching: find.text(text),
    );

    expect(inKpi(WidgetKeys.homeKpiTopAuthor, 'Ashish Vaswani'), findsOneWidget);
    expect(inKpi(WidgetKeys.homeKpiTopJournal, 'NeurIPS'), findsOneWidget);
    expect(inKpi(WidgetKeys.homeKpiMostActiveYear, '2021'), findsOneWidget);
    expect(
      inKpi(WidgetKeys.homeKpiAverageCitations, '150.0'), // (300+100+50)/3
      findsOneWidget,
    );
    expect(
      inKpi(WidgetKeys.homeKpiMostInfluential, 'Attention Is All You Need'),
      findsOneWidget,
    );
  });

  testWidgets('renders the yearly trend chart and tappable publications', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpHome(tester);

    expect(find.byKey(WidgetKeys.homeTrendChart), findsOneWidget);
    expect(find.byKey(WidgetKeys.homePublication(0)), findsOneWidget);
    expect(find.byKey(WidgetKeys.homePublication(1)), findsOneWidget);
    expect(find.byKey(WidgetKeys.homePublication(2)), findsOneWidget);
  });
}
