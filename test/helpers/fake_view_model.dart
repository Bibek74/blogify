
import 'package:blogify/features/auth/presentation/state/auth_state.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() {
    // Don’t read usecases in tests
    return const AuthState(status: AuthStatus.initial);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    // no-op for now
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // no-op
  }

  // helpers (optional) if you want to force states from tests later
  void emitLoading() => state = state.copyWith(status: AuthStatus.loading);

  void emitError(String message) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );

  void emitRegistered() => state = state.copyWith(status: AuthStatus.registered);

  void emitAuthenticated() =>
      state = state.copyWith(status: AuthStatus.authenticated);
}
