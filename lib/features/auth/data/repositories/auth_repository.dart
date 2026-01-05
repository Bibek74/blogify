import 'package:blogify/core/error/failures.dart';
import 'package:blogify/features/auth/data/datasources/auth_datasource.dart';
import 'package:blogify/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:blogify/features/auth/data/models/auth_hive_model.dart';
import 'package:blogify/features/auth/domain/entities/auth_entity.dart';
import 'package:blogify/features/auth/domain/repositories/auth_repositories.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(authDatasource: ref.read(authLocalDatasourceProvider));
});

class AuthRepository implements IAuthRepository{

  final IAuthDatasource _authDatasource;

  AuthRepository({required IAuthDatasource authDatasource})
   : _authDatasource = authDatasource;
  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try{
      final user = await _authDatasource.getCurrentUser();
      if (user != null){
        final entity = user.toEntity();
        return Right(entity);
      }
      return Left(LocalDatabaseFailure(message: 'No current user found'));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
    
  }

  @override
  Future<Either<Failure, AuthEntity>> login(String email, String password) async{
    try{
      final user = await _authDatasource.login(email, password);
      if (user != null){
        final entity = user.toEntity();
        return Right(entity);
      }
      return Left(LocalDatabaseFailure(message: 'Invalid email or password'));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try{
      final result = await _authDatasource.logout();
      if (result){
        return Right(true);
      } else {
        return Left(LocalDatabaseFailure(message: 'Logout failed'));
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> register(AuthEntity entity) async {
    try{
      final model = AuthHiveModel.fromEntity(entity);
      final result = await _authDatasource.register(model);
      if (result){
        return Right(true);
      } else {
        return Left(LocalDatabaseFailure(message: 'Registration failed'));
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}