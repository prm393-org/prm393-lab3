import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/paged.dart';
import '../entities/work.dart';
import '../repositories/publication_repository.dart';

class GetWorksByKeyword
    implements UseCase<Paged<Work>, GetWorksByKeywordParams> {
  final PublicationRepository _repository;
  GetWorksByKeyword(this._repository);

  @override
  Future<Either<Failure, Paged<Work>>> call(GetWorksByKeywordParams params) =>
      _repository.getWorksByKeyword(
        params.keywordId,
        page: params.page,
        perPage: params.perPage,
        sort: params.sort,
      );
}

class GetWorksByKeywordParams extends Equatable {
  final String keywordId;
  final int page;
  final int perPage;
  final String sort;

  const GetWorksByKeywordParams({
    required this.keywordId,
    this.page = 1,
    this.perPage = 25,
    this.sort = 'cited_by_count:desc',
  });

  @override
  List<Object?> get props => [keywordId, page, perPage, sort];
}
