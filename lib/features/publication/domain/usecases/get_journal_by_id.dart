import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/journal_summary.dart';
import '../repositories/publication_repository.dart';

class GetJournalById implements UseCase<JournalSummary, GetJournalByIdParams> {
  final PublicationRepository _repository;

  GetJournalById(this._repository);

  @override
  Future<Either<Failure, JournalSummary>> call(GetJournalByIdParams params) =>
      _repository.getJournalById(params.journalId);
}

class GetJournalByIdParams extends Equatable {
  final String journalId;

  const GetJournalByIdParams({required this.journalId});

  @override
  List<Object?> get props => [journalId];
}
