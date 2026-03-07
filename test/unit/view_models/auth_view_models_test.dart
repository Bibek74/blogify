import 'package:blogify/app/theme/theme_mode_provider.dart';
import 'package:blogify/core/error/failures.dart';
import 'package:blogify/features/auth/domain/entities/auth_entity.dart';
import 'package:blogify/features/auth/domain/usecases/get_current_usecase.dart';
import 'package:blogify/features/auth/domain/usecases/login_usecase.dart';
import 'package:blogify/features/auth/domain/usecases/logout_usecase.dart';
import 'package:blogify/features/auth/domain/usecases/register_usecase.dart';
import 'package:blogify/features/auth/presentation/state/auth_state.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRegisterUsecase extends Mock implements RegisterUsecase {}

class MockLoginUsecase extends Mock implements LoginUsecase {}

class MockGetCurrentUserUsecase extends Mock implements GetCurrentUserUsecase {}

class MockLogoutUsecase extends Mock implements LogoutUsecase {}

void main() {
  late MockRegisterUsecase registerUsecase;
  late MockLoginUsecase loginUsecase;
  late MockGetCurrentUserUsecase getCurrentUserUsecase;
  late MockLogoutUsecase logoutUsecase;

  setUpAll(() {
    registerFallbackValue(
      const RegisterParams(
        fullName: 'Fallback',
        email: 'fallback@mail.com',
        password: '123456',
      ),
    );
    registerFallbackValue(
      const LoginParams(email: 'fallback@mail.com', password: '123456'),
    );
  });

  setUp(() {
    registerUsecase = MockRegisterUsecase();
    loginUsecase = MockLoginUsecase();
    getCurrentUserUsecase = MockGetCurrentUserUsecase();
    logoutUsecase = MockLogoutUsecase();
  });

  ProviderContainer _createContainer() {
    return ProviderContainer(
      overrides: [
        registerUsecaseProvider.overrideWithValue(registerUsecase),
        loginUsecaseProvider.overrideWithValue(loginUsecase),
        getCurrentUserUsecaseProvider.overrideWithValue(getCurrentUserUsecase),
        logoutUsecaseProvider.overrideWithValue(logoutUsecase),
      ],
    );
  }

  group('View model unit tests', () {
    test('1. AuthViewModel starts in initial state', () {
      final container = _createContainer();
      addTearDown(container.dispose);

      final state = container.read(authViewModelProvider);

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('2. register success sets status to registered', () async {
      when(
        () => registerUsecase(any()),
      ).thenAnswer((_) async => const Right(true));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.register(
        fullName: 'Alice',
        email: 'alice@mail.com',
        password: '123456',
      );

      expect(
        container.read(authViewModelProvider).status,
        AuthStatus.registered,
      );
    });

    test('3. register failure sets status error with message', () async {
      const failure = ApiFailure(message: 'Email exists', statusCode: 409);
      when(
        () => registerUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.register(
        fullName: 'Alice',
        email: 'alice@mail.com',
        password: '123456',
      );

      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Email exists');
    });

    test('4. register passes generated username from email prefix', () async {
      RegisterParams? captured;
      when(() => registerUsecase(any())).thenAnswer((invocation) async {
        captured = invocation.positionalArguments.first as RegisterParams;
        return const Right(true);
      });

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.register(
        fullName: 'Bob',
        email: 'bob.smith@mail.com',
        password: '123456',
      );

      expect(captured, isNotNull);
      expect(captured!.username, 'bob.smith');
    });

    test('5. login success sets authenticated status and user', () async {
      const user = AuthEntity(fullName: 'Kate', email: 'kate@mail.com');
      when(
        () => loginUsecase(any()),
      ).thenAnswer((_) async => const Right(user));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.login(email: 'kate@mail.com', password: '123456');

      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, user);
    });

    test('6. login failure sets status error and message', () async {
      const failure = ApiFailure(message: 'Bad credentials', statusCode: 401);
      when(
        () => loginUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.login(email: 'x@mail.com', password: 'bad');

      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Bad credentials');
    });

    test('7. getCurrentUser success sets authenticated state', () async {
      const user = AuthEntity(fullName: 'Nina', email: 'nina@mail.com');
      when(
        () => getCurrentUserUsecase(),
      ).thenAnswer((_) async => const Right(user));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.getCurrentUser();

      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, user);
    });

    test('8. getCurrentUser failure sets unauthenticated state', () async {
      const failure = ApiFailure(message: 'Session expired', statusCode: 401);
      when(
        () => getCurrentUserUsecase(),
      ).thenAnswer((_) async => const Left(failure));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.getCurrentUser();

      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Session expired');
    });

    test('9. logout success sets unauthenticated status', () async {
      const user = AuthEntity(fullName: 'Nina', email: 'nina@mail.com');
      when(
        () => loginUsecase(any()),
      ).thenAnswer((_) async => const Right(user));
      when(() => logoutUsecase()).thenAnswer((_) async => const Right(true));

      final container = _createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.login(email: 'nina@mail.com', password: '123456');
      await notifier.logout();

      final state = container.read(authViewModelProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, user);
    });

    test('10. ThemeModeController updates mode and persists value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final controller = ThemeModeController(prefs);
      expect(controller.state, ThemeMode.light);

      await controller.setDarkMode(true);

      expect(controller.state, ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), ThemeMode.dark.name);
    });
  });
}
