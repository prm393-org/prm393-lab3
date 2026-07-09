import 'package:equatable/equatable.dart';

/// Failures trả về tầng domain/presentation (kết hợp với dartz `Either`).
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error']);
}

class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Invalid data']);
}
