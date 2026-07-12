import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:journal_trend_analyzer/app.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/core/providers/core_providers.dart';
import 'package:journal_trend_analyzer/features/profile/domain/entities/user_settings.dart';
import 'package:journal_trend_analyzer/features/profile/domain/repositories/profile_repository.dart';
import 'package:journal_trend_analyzer/features/profile/providers/profile_providers.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/journal_summary.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/domain/repositories/publication_repository.dart';
import 'package:journal_trend_analyzer/features/publication/providers/publication_providers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('App starts and shows setup placeholder page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // Thay repository thật bằng bản in-memory: chỉ cần override ở tầng
        // repository, mọi use case phía trên tự lấy theo.
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          publicationRepositoryProvider.overrideWithValue(
            _InMemoryPublicationRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(
            _InMemoryProfileRepository(),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _InMemoryPublicationRepository implements PublicationRepository {
  @override
  Future<Either<Failure, List<JournalSummary>>> getJournalsByTopic({
    required String topicId,
    int limit = 10,
  }) async => const Right([]);

  @override
  Future<Either<Failure, JournalSummary>> getJournalById(
    String journalId,
  ) async =>
      const Left(ServerFailure('Not implemented in test', statusCode: 501));

  @override
  Future<Either<Failure, Paged<Work>>> getWorksByJournal({
    required String journalId,
    String? topicId,
    int page = 1,
    int perPage = 20,
    String sort = 'cited_by_count:desc',
  }) async =>
      Right(Paged(items: const [], total: 0, page: page, perPage: perPage));

  @override
  Future<Either<Failure, Paged<Topic>>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  }) async {
    return Right(
      Paged<Topic>(items: const [], total: 0, page: page, perPage: perPage),
    );
  }

  @override
  Future<Either<Failure, Paged<Work>>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  }) async {
    return Right(
      Paged<Work>(items: const [], total: 0, page: page, perPage: perPage),
    );
  }

  @override
  Future<Either<Failure, List<TrendPoint>>> getTopicTrend(
    String topicId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Work>> getWorkById(String workId) async {
    return Left(ServerFailure('Not implemented in test', statusCode: 501));
  }
}

class _InMemoryProfileRepository implements ProfileRepository {
  @override
  Future<UserSettings> loadSettings() async => const UserSettings();

  @override
  Future<void> saveSettings(UserSettings settings) async {}

  @override
  Future<void> resetSettings() async {}
}
