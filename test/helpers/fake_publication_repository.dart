import 'package:dartz/dartz.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/journal_summary.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/domain/repositories/publication_repository.dart';

class FakePublicationRepository implements PublicationRepository {
  Either<Failure, List<JournalSummary>> journalsResult = const Right([]);
  Either<Failure, JournalSummary> journalResult = const Left(
    ServerFailure('Missing journal'),
  );
  final List<Either<Failure, Paged<Work>>> worksByJournalResults = [];
  Either<Failure, Paged<Work>>? worksByTopicResult;
  Either<Failure, List<TrendPoint>> topicTrendResult = const Right([]);
  Either<Failure, Work> workByIdResult = const Left(ServerFailure('Not used'));
  int journalsCalls = 0;
  int journalCalls = 0;
  int worksByJournalCalls = 0;
  int worksByTopicCalls = 0;
  int? lastJournalLimit;
  String? lastWorksSort;
  int? lastWorksPage;
  String? lastTopicId;

  @override
  Future<Either<Failure, List<JournalSummary>>> getJournalsByTopic({
    required String topicId,
    int limit = 10,
  }) async {
    journalsCalls++;
    lastJournalLimit = limit;
    return journalsResult;
  }

  @override
  Future<Either<Failure, JournalSummary>> getJournalById(
    String journalId,
  ) async {
    journalCalls++;
    return journalResult;
  }

  @override
  Future<Either<Failure, Paged<Work>>> getWorksByJournal({
    required String journalId,
    String? topicId,
    int page = 1,
    int perPage = 20,
    String sort = 'cited_by_count:desc',
  }) async {
    lastWorksSort = sort;
    lastWorksPage = page;
    final index = worksByJournalCalls++;
    if (worksByJournalResults.isEmpty) {
      return Right(
        Paged(items: const [], total: 0, page: page, perPage: perPage),
      );
    }
    final safeIndex = index.clamp(0, worksByJournalResults.length - 1);
    return worksByJournalResults[safeIndex];
  }

  @override
  Future<Either<Failure, Work>> getWorkById(String workId) async =>
      workByIdResult;

  @override
  Future<Either<Failure, List<TrendPoint>>> getTopicTrend(
    String topicId,
  ) async => topicTrendResult;

  @override
  Future<Either<Failure, List<TrendPoint>>> getKeywordTrend(
    String keywordId,
  ) async => const Right([]);

  @override
  Future<Either<Failure, Paged<Work>>> getWorksByKeyword(
    String keywordId, {
    int page = 1,
    int perPage = 25,
    String sort = 'cited_by_count:desc',
  }) async =>
      Right(Paged(items: const [], total: 0, page: page, perPage: perPage));

  @override
  Future<Either<Failure, Paged<Work>>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  }) async {
    worksByTopicCalls++;
    lastTopicId = topicId;
    lastWorksSort = sort;
    return worksByTopicResult ??
        Right(Paged(items: const [], total: 0, page: page, perPage: perPage));
  }

  @override
  Future<Either<Failure, Paged<Topic>>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  }) async =>
      Right(Paged(items: const [], total: 0, page: page, perPage: perPage));
}
