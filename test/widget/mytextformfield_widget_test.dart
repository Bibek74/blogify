import 'package:blogify/core/widgets/mytextfeild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required Widget child, GlobalKey<FormState>? formKey}) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        key: formKey,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  group('MyTextformfield widget tests', () {
    testWidgets('1. renders label and hint text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          child: MyTextformfield(
            labelText: 'Email',
            hintText: 'Enter email',
            controller: controller,
            errorMessage: 'Required',
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter email'), findsOneWidget);
    });

    testWidgets('2. uses obscureText when true', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          child: MyTextformfield(
            labelText: 'Password',
            hintText: 'Enter password',
            controller: controller,
            errorMessage: 'Required',
            obscureText: true,
          ),
        ),
      );

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, true);
    });

    testWidgets('3. applies keyboard type', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          child: MyTextformfield(
            labelText: 'Email',
            hintText: 'Email',
            controller: controller,
            errorMessage: 'Required',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      );

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('4. default validator returns error for empty value', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          formKey: formKey,
          child: MyTextformfield(
            labelText: 'Name',
            hintText: 'Name',
            controller: controller,
            errorMessage: 'Name required',
          ),
        ),
      );

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, false);
      expect(find.text('Name required'), findsOneWidget);
    });

    testWidgets('5. default validator passes for non-empty value', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'Alex');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          formKey: formKey,
          child: MyTextformfield(
            labelText: 'Name',
            hintText: 'Name',
            controller: controller,
            errorMessage: 'Name required',
          ),
        ),
      );

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, true);
      expect(find.text('Name required'), findsNothing);
    });

    testWidgets('6. custom validator overrides default validator', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          formKey: formKey,
          child: MyTextformfield(
            labelText: 'Code',
            hintText: 'Code',
            controller: controller,
            errorMessage: 'Should not be used',
            validator: (value) => value == 'xyz' ? null : 'Custom error',
          ),
        ),
      );

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, false);
      expect(find.text('Custom error'), findsOneWidget);
      expect(find.text('Should not be used'), findsNothing);
    });

    testWidgets('7. binds and updates controller text', (tester) async {
      final controller = TextEditingController(text: 'old');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          child: MyTextformfield(
            labelText: 'Field',
            hintText: 'Hint',
            controller: controller,
            errorMessage: 'Required',
          ),
        ),
      );

      expect(find.text('old'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'new value');
      await tester.pump();

      expect(controller.text, 'new value');
    });
  });
}
