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
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Signup: shows snackbar when fields are empty', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    // Scroll to the button first
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Please enter your name'), findsOneWidget);
  });

  testWidgets('Signup: non-gmail email shows snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    // Fill fields - intentionally mismatched passwords
    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john_doe');
    await tester.enterText(find.byType(TextField).at(2), 'john@example.com');
    await tester.enterText(find.byType(TextField).at(3), '1234567');
    await tester.enterText(find.byType(TextField).at(4), '7654321');

    // Scroll to the button first
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
