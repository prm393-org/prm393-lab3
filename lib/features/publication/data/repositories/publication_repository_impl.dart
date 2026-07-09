import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/paged.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/trend_point.dart';
import '../../domain/entities/work.dart';
import '../../domain/repositories/publication_repository.dart';
import '../datasources/publication_remote_datasource.dart';

class PublicationRepositoryImpl implements PublicationRepository {
  final PublicationRemoteDatasource _datasource;
  final NetworkInfo _networkInfo;

  PublicationRepositoryImpl({
    required PublicationRemoteDatasource datasource,
    required NetworkInfo networkInfo,
  })  : _datasource = datasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, Paged<Topic>>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  }) =>
      _run(() async {
        final r = await _datasource.searchTopics(
            query: query, sort: sort, page: page, perPage: perPage);
        return Paged<Topic>(
          items: r.items,
          total: r.total,
          page: page,
          perPage: perPage,
        );
      });

  @override
  Future<Either<Failure, Paged<Work>>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  }) =>
      _run(() async {
        final r = await _datasource.getWorksByTopic(topicId,
            page: page, perPage: perPage, year: year, sort: sort);
        return Paged<Work>(
          items: r.items,
          total: r.total,
          page: page,
          perPage: perPage,
        );
      });

  @override
  Future<Either<Failure, List<TrendPoint>>> getTopicTrend(String topicId) =>
      _run(() => _datasource.getTopicTrend(topicId));

  @override
  Future<Either<Failure, Work>> getWorkById(String workId) =>
      _run(() => _datasource.getWorkById(workId));

  Future<Either<Failure, T>> _run<T>(Future<T> Function() call) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    }
  }
}
