import 'package:blogify/features/auth/presentation/state/auth_state.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() {
    // initial state for UI
    return const AuthState(status: AuthStatus.initial);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    // no-op for now (widget tests for snackbars/navigation don’t need real login)
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String username,
  }) async {
    // no-op for now (widget tests for snackbars/navigation don't need real registration)
  }
}
