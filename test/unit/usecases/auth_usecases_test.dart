import 'package:blogify/core/error/failures.dart';
import 'package:blogify/features/auth/domain/entities/auth_entity.dart';
import 'package:blogify/features/auth/domain/repositories/auth_repositories.dart';
import 'package:blogify/features/auth/domain/usecases/get_current_usecase.dart';
import 'package:blogify/features/auth/domain/usecases/login_usecase.dart';
import 'package:blogify/features/auth/domain/usecases/logout_usecase.dart';
import 'package:blogify/features/auth/domain/usecases/register_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const AuthEntity(fullName: 'Fallback', email: 'fallback@mail.com'),
    );
  });

  setUp(() {
    repository = MockAuthRepository();
  });

  group('Auth usecases', () {
    test('1. LoginParams equality works for same values', () {
      const p1 = LoginParams(email: 'a@b.com', password: '123456');
      const p2 = LoginParams(email: 'a@b.com', password: '123456');

      expect(p1, equals(p2));
      expect(p1.props, equals(p2.props));
    });

    test('2. RegisterParams equality works for same values', () {
      const p1 = RegisterParams(
        fullName: 'Alex',
        username: 'alex',
        email: 'alex@mail.com',
        password: 'pass123',
      );
      const p2 = RegisterParams(
        fullName: 'Alex',
        username: 'alex',
        email: 'alex@mail.com',
        password: 'pass123',
      );

      expect(p1, equals(p2));
      expect(p1.props, equals(p2.props));
    });

    test(
      '3. LoginUsecase calls repository.login with incoming params',
      () async {
        const params = LoginParams(email: 'john@mail.com', password: 'secret');
        final user = const AuthEntity(fullName: 'John', email: 'john@mail.com');

        when(
          () => repository.login(params.email, params.password),
        ).thenAnswer((_) async => Right(user));

        final usecase = LoginUsecase(authRepository: repository);
        final result = await usecase(params);

        expect(result, Right<Failure, AuthEntity>(user));
        verify(() => repository.login(params.email, params.password)).called(1);
      },
    );

    test('4. LoginUsecase returns repository failure as-is', () async {
      const params = LoginParams(email: 'john@mail.com', password: 'secret');
      const failure = ApiFailure(
        message: 'Invalid credentials',
        statusCode: 401,
      );

      when(
        () => repository.login(params.email, params.password),
      ).thenAnswer((_) async => const Left(failure));

      final usecase = LoginUsecase(authRepository: repository);
      final result = await usecase(params);

      expect(result, const Left<Failure, AuthEntity>(failure));
    });

    test(
      '5. RegisterUsecase maps entity and derives username from email',
      () async {
        AuthEntity? captured;
        const params = RegisterParams(
          fullName: 'Mina',
          email: 'mina@mail.com',
          password: '123456',
        );

        when(() => repository.register(any())).thenAnswer((invocation) async {
          captured = invocation.positionalArguments.first as AuthEntity;
          return const Right(true);
        });

        final usecase = RegisterUsecase(authRepository: repository);
        final result = await usecase(params);

        expect(result, const Right<Failure, bool>(true));
        expect(captured, isNotNull);
        expect(captured!.fullName, 'Mina');
        expect(captured!.email, 'mina@mail.com');
        expect(captured!.password, '123456');
        expect(captured!.username, 'mina');
      },
    );

    test('6. RegisterUsecase keeps provided username', () async {
      AuthEntity? captured;
      const params = RegisterParams(
        fullName: 'Mina',
        username: 'mina_custom',
        email: 'mina@mail.com',
        password: '123456',
      );

      when(() => repository.register(any())).thenAnswer((invocation) async {
        captured = invocation.positionalArguments.first as AuthEntity;
        return const Right(true);
      });

      final usecase = RegisterUsecase(authRepository: repository);
      await usecase(params);

      expect(captured?.username, 'mina_custom');
    });

    test('7. RegisterUsecase returns repository failure as-is', () async {
      const params = RegisterParams(
        fullName: 'Mina',
        email: 'mina@mail.com',
        password: '123456',
      );
      const failure = ApiFailure(
        message: 'Email already exists',
        statusCode: 409,
      );

      when(
        () => repository.register(any()),
      ).thenAnswer((_) async => const Left(failure));

      final usecase = RegisterUsecase(authRepository: repository);
      final result = await usecase(params);

      expect(result, const Left<Failure, bool>(failure));
    });

    test('8. GetCurrentUserUsecase returns user from repository', () async {
      final user = const AuthEntity(fullName: 'Ana', email: 'ana@mail.com');

      when(
        () => repository.getCurrentUser(),
      ).thenAnswer((_) async => Right(user));

      final usecase = GetCurrentUserUsecase(authRepository: repository);
      final result = await usecase();

      expect(result, Right<Failure, AuthEntity>(user));
      verify(() => repository.getCurrentUser()).called(1);
    });

    test('9. LogoutUsecaseImpl returns success from repository', () async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Right(true));

      final usecase = LogoutUsecaseImpl(authRepository: repository);
      final result = await usecase();

      expect(result, const Right<Failure, bool>(true));
      verify(() => repository.logout()).called(1);
    });

    test('10. LogoutUsecaseImpl returns failure from repository', () async {
      const failure = ApiFailure(message: 'Network error', statusCode: 500);
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Left(failure));

      final usecase = LogoutUsecaseImpl(authRepository: repository);
      final result = await usecase();

      expect(result, const Left<Failure, bool>(failure));
    });
  });
}
