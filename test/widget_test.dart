import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blogify/app/routes/app.dart';

void main() {
	testWidgets('app builds', (WidgetTester tester) async {
		await tester.pumpWidget(const App());
		await tester.pump();
		await tester.pump(const Duration(seconds: 2));
		await tester.pumpAndSettle();
		expect(find.byType(MaterialApp), findsOneWidget);
	});
}
