import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Base class cho mọi use case trong tầng domain.
///
/// `T`      : kiểu dữ liệu trả về khi thành công.
/// `Params` : tham số đầu vào (dùng [NoParams] nếu không cần).
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Dùng cho use case không cần tham số.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
