import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/journal_summary.dart';
import '../repositories/publication_repository.dart';

class GetJournalsByTopic
    implements UseCase<List<JournalSummary>, GetJournalsByTopicParams> {
  final PublicationRepository _repository;

  GetJournalsByTopic(this._repository);

  @override
  Future<Either<Failure, List<JournalSummary>>> call(
    GetJournalsByTopicParams params,
  ) => _repository.getJournalsByTopic(
    topicId: params.topicId,
    limit: params.limit,
  );
}

class GetJournalsByTopicParams extends Equatable {
  final String topicId;
  final int limit;

  const GetJournalsByTopicParams({required this.topicId, this.limit = 10});

  @override
  List<Object?> get props => [topicId, limit];
}
