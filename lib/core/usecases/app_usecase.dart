import 'package:blogify/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract interface class UsecaseWithParms<SucessType, Params> {
  Future<Either<Failure, SucessType>> call(Params params);
}

abstract interface class UsecaseWithoutParms<SuccessType> {
  Future<Either<Failure, SuccessType>> call();
}