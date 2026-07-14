import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/providers/core_providers.dart';
import 'package:journal_trend_analyzer/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';
import 'package:journal_trend_analyzer/firebase/analytics_service.dart';
import 'package:journal_trend_analyzer/firebase/firebase_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fake_publication_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late List<(String, Map<String, Object>?)> events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    events = [];
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        publicationRepositoryProvider.overrideWithValue(
          FakePublicationRepository(),
        ),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService.forTesting((name, parameters) async {
            events.add((name, parameters));
          }),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('logs search_topic with the keyword parameter', () async {
    await container
        .read(homeViewModelProvider.notifier)
        .search('  quantum computing  ');

    expect(events, hasLength(1));
    expect(events.single.$1, 'search_topic');
    // Query đã trim trước khi log — không gửi khoảng trắng lên Analytics.
    expect(events.single.$2?['keyword'], 'quantum computing');
  });

  test('clearing the search box does not log an empty search_topic', () async {
    await container.read(homeViewModelProvider.notifier).search('   ');

    expect(events, isEmpty);
  });
}
