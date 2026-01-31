import 'package:blogify/features/auth/presentation/pages/login_screen.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/fake_view_model.dart';


void main() {
  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      overrides: [
        // ✅ NotifierProvider override: no ref parameter
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Login: shows snackbar when email/password are empty',
      (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    // Scroll to the button first
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // show snackbar

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('Login: tapping "Create Account" navigates to SignupScreen',
    (tester) async {
  await tester.pumpWidget(wrapWithApp(const LoginScreen()));

  // The footer link might be off-screen, so ensure it's visible
  await tester.ensureVisible(find.text('Create Account').last);
  await tester.tap(find.text('Create Account').last);
  await tester.pumpAndSettle();

  expect(find.byType(SignupScreen), findsOneWidget);
});
}
