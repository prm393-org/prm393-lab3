import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/paged.dart';
import '../entities/work.dart';
import '../repositories/publication_repository.dart';

class GetWorksByTopic implements UseCase<Paged<Work>, GetWorksByTopicParams> {
  final PublicationRepository _repository;
  GetWorksByTopic(this._repository);

  @override
  Future<Either<Failure, Paged<Work>>> call(GetWorksByTopicParams params) =>
      _repository.getWorksByTopic(
        params.topicId,
        page: params.page,
        perPage: params.perPage,
        year: params.year,
        sort: params.sort,
      );
}

class GetWorksByTopicParams extends Equatable {
  final String topicId;
  final int page;
  final int perPage;
  final int? year;
  final String sort;

  const GetWorksByTopicParams({
    required this.topicId,
    this.page = 1,
    this.perPage = 25,
    this.year,
    this.sort = 'cited_by_count:desc',
  });

  @override
  List<Object?> get props => [topicId, page, perPage, year, sort];
}
