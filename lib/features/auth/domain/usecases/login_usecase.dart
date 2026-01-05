import 'package:blogify/core/error/failures.dart' show Failure;
import 'package:blogify/core/usecases/app_usecase.dart';
import 'package:blogify/features/auth/data/repositories/auth_repository.dart';
import 'package:blogify/features/auth/domain/entities/auth_entity.dart';
import 'package:blogify/features/auth/domain/repositories/auth_repositories.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginParams extends Equatable {

  final String email;
  final String password;
  const LoginParams({
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [email, password];
}

// prvider for login usecase
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return LoginUsecase(authRepository: authRepository);
});
    

class LoginUsecase implements UsecaseWithParms<AuthEntity, LoginParams> {
 
  final IAuthRepository _authRepository;
  LoginUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;
  @override
  Future<Either<Failure, AuthEntity>> call(LoginParams params) {
    return _authRepository.login(params.email, params.password);
  }

} 