import 'package:blogify/core/widgets/mybutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('MyButton widget tests', () {
    testWidgets('1. renders provided text', (tester) async {
      await tester.pumpWidget(
        _wrap(const MyButton(onPressed: null, text: 'Continue')),
      );

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('2. is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const MyButton(onPressed: null, text: 'Disabled')),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('3. executes callback when tapped', (tester) async {
      var tapped = 0;

      await tester.pumpWidget(
        _wrap(
          MyButton(
            onPressed: () {
              tapped += 1;
            },
            text: 'Tap me',
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('4. has full width sized box wrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(const MyButton(onPressed: null, text: 'Width')),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('5. enabled button background is blueAccent', (tester) async {
      await tester.pumpWidget(
        _wrap(MyButton(onPressed: () {}, text: 'Enabled')),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final bgColor = button.style?.backgroundColor?.resolve({});
      expect(bgColor, Colors.blueAccent);
    });

    testWidgets('6. disabled button background is grey', (tester) async {
      await tester.pumpWidget(
        _wrap(const MyButton(onPressed: null, text: 'Disabled')),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final bgColor = button.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(bgColor, Colors.grey);
    });

    testWidgets('7. uses expected text style', (tester) async {
      await tester.pumpWidget(_wrap(MyButton(onPressed: () {}, text: 'Style')));

      final text = tester.widget<Text>(find.text('Style'));
      expect(text.style?.fontSize, 20);
      expect(text.style?.color, Colors.white);
    });
  });
}
