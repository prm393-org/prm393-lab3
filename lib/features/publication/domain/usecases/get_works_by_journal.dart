import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/paged.dart';
import '../entities/work.dart';
import '../repositories/publication_repository.dart';

class GetWorksByJournal
    implements UseCase<Paged<Work>, GetWorksByJournalParams> {
  final PublicationRepository _repository;

  GetWorksByJournal(this._repository);

  @override
  Future<Either<Failure, Paged<Work>>> call(GetWorksByJournalParams params) =>
      _repository.getWorksByJournal(
        journalId: params.journalId,
        topicId: params.topicId,
        page: params.page,
        perPage: params.perPage,
        sort: params.sort,
      );
}

class GetWorksByJournalParams extends Equatable {
  final String journalId;
  final String? topicId;
  final int page;
  final int perPage;
  final String sort;

  const GetWorksByJournalParams({
    required this.journalId,
    this.topicId,
    this.page = 1,
    this.perPage = 20,
    this.sort = 'cited_by_count:desc',
  });

  @override
  List<Object?> get props => [journalId, topicId, page, perPage, sort];
}
