import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trend_point.dart';
import '../repositories/publication_repository.dart';

class GetTopicTrend implements UseCase<List<TrendPoint>, GetTopicTrendParams> {
  final PublicationRepository _repository;
  GetTopicTrend(this._repository);

  @override
  Future<Either<Failure, List<TrendPoint>>> call(GetTopicTrendParams params) =>
      _repository.getTopicTrend(params.topicId);
}

class GetTopicTrendParams extends Equatable {
  final String topicId;
  const GetTopicTrendParams({required this.topicId});

  @override
  List<Object?> get props => [topicId];
}
