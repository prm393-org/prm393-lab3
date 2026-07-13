import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trend_point.dart';
import '../repositories/publication_repository.dart';

class GetKeywordTrend
    implements UseCase<List<TrendPoint>, GetKeywordTrendParams> {
  final PublicationRepository _repository;
  GetKeywordTrend(this._repository);

  @override
  Future<Either<Failure, List<TrendPoint>>> call(GetKeywordTrendParams params) =>
      _repository.getKeywordTrend(params.keywordId);
}

class GetKeywordTrendParams extends Equatable {
  final String keywordId;
  const GetKeywordTrendParams({required this.keywordId});

  @override
  List<Object?> get props => [keywordId];
}
