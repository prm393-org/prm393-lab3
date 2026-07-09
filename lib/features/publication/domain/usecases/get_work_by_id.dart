import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/work.dart';
import '../repositories/publication_repository.dart';

class GetWorkById implements UseCase<Work, GetWorkByIdParams> {
  final PublicationRepository _repository;
  GetWorkById(this._repository);

  @override
  Future<Either<Failure, Work>> call(GetWorkByIdParams params) =>
      _repository.getWorkById(params.workId);
}

class GetWorkByIdParams extends Equatable {
  final String workId;

  const GetWorkByIdParams({required this.workId});

  @override
  List<Object?> get props => [workId];
}
