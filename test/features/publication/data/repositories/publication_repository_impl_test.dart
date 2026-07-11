import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/error/exceptions.dart';
import 'package:journal_trend_analyzer/core/error/failures.dart';
import 'package:journal_trend_analyzer/core/network/network_info.dart';
import 'package:journal_trend_analyzer/features/publication/data/datasources/publication_remote_datasource.dart';
import 'package:journal_trend_analyzer/features/publication/data/models/journal_summary_model.dart';
import 'package:journal_trend_analyzer/features/publication/data/models/topic_model.dart';
import 'package:journal_trend_analyzer/features/publication/data/models/work_model.dart';
import 'package:journal_trend_analyzer/features/publication/data/repositories/publication_repository_impl.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';

void main() {
  const journal = JournalSummaryModel(
    id: 'https://openalex.org/S1',
    displayName: 'Journal',
    publicationCount: 10,
    citationCount: 30,
  );

  test('repository maps journal datasource success', () async {
    final repository = PublicationRepositoryImpl(
      datasource: _FakeDatasource(journals: const [journal]),
      networkInfo: _ConnectedNetwork(),
    );
    final result = await repository.getJournalsByTopic(topicId: 'T1');

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => const []), [journal]);
  });

  test('repository maps typed datasource exception to typed failure', () async {
    final repository = PublicationRepositoryImpl(
      datasource: _FakeDatasource(throwServerError: true),
      networkInfo: _ConnectedNetwork(),
    );
    final result = await repository.getJournalById('S1');

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
    }, (_) => fail('Expected a failure'));
  });
}

class _ConnectedNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _FakeDatasource implements PublicationRemoteDatasource {
  final List<JournalSummaryModel> journals;
  final bool throwServerError;

  _FakeDatasource({this.journals = const [], this.throwServerError = false});

  Never _throw() =>
      throw const ServerException('Service unavailable', statusCode: 503);

  @override
  Future<JournalSummaryModel> getJournalById(String journalId) async {
    if (throwServerError) _throw();
    return journals.first;
  }

  @override
  Future<List<JournalSummaryModel>> getJournalsByTopic({
    required String topicId,
    int limit = 10,
  }) async {
    if (throwServerError) _throw();
    return journals;
  }

  @override
  Future<WorkModel> getWorkById(String workId) async => _throw();

  @override
  Future<PageResult<WorkModel>> getWorksByJournal({
    required String journalId,
    String? topicId,
    int page = 1,
    int perPage = 20,
    String sort = 'cited_by_count:desc',
  }) async => (items: const <WorkModel>[], total: 0);

  @override
  Future<PageResult<WorkModel>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  }) async => (items: const <WorkModel>[], total: 0);

  @override
  Future<PageResult<TopicModel>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  }) async => (items: const <TopicModel>[], total: 0);

  @override
  Future<List<TrendPoint>> getTopicTrend(String topicId) async => const [];
}
