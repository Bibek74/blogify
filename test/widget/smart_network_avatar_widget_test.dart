import 'package:blogify/core/widgets/smart_network_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AvatarHost extends StatefulWidget {
  const _AvatarHost({required this.initialUrls});

  final List<String> initialUrls;

  @override
  State<_AvatarHost> createState() => _AvatarHostState();
}

class _AvatarHostState extends State<_AvatarHost> {
  late List<String> urls;

  @override
  void initState() {
    super.initState();
    urls = widget.initialUrls;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SmartNetworkAvatar(
              radius: 30,
              imageUrls: urls,
              backgroundColor: Colors.amber,
              fallback: const Icon(Icons.person, key: Key('fallback-icon')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  urls = const ['https://example.com/avatar.png'];
                });
              },
              child: const Text('set-non-empty'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  urls = const [];
                });
              },
              child: const Text('set-empty'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _wrap(SmartNetworkAvatar child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SmartNetworkAvatar widget tests', () {
    testWidgets('1. shows fallback child when url list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SmartNetworkAvatar(
            radius: 24,
            imageUrls: [],
            fallback: Icon(Icons.person, key: Key('fallback-icon')),
          ),
        ),
      );

      expect(find.byKey(const Key('fallback-icon')), findsOneWidget);
    });

    testWidgets('2. applies radius to CircleAvatar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SmartNetworkAvatar(
            radius: 44,
            imageUrls: [],
            fallback: Icon(Icons.person),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, 44);
    });

    testWidgets('3. applies background color', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SmartNetworkAvatar(
            radius: 24,
            imageUrls: [],
            backgroundColor: Colors.green,
            fallback: Icon(Icons.person),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, Colors.green);
    });

    testWidgets(
      '4. uses first URL as background image when list is not empty',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const SmartNetworkAvatar(
              radius: 24,
              imageUrls: [
                'https://example.com/a.png',
                'https://example.com/b.png',
              ],
              fallback: Icon(Icons.person),
            ),
          ),
        );

        final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        final image = avatar.backgroundImage;

        expect(image, isA<NetworkImage>());
        expect((image as NetworkImage).url, 'https://example.com/a.png');
        expect(avatar.child, isNull);
      },
    );

    testWidgets('5. fallback disappears after list changes to non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(const _AvatarHost(initialUrls: []));

      expect(find.byKey(const Key('fallback-icon')), findsOneWidget);

      await tester.tap(find.text('set-non-empty'));
      await tester.pump();

      expect(find.byKey(const Key('fallback-icon')), findsNothing);
    });

    testWidgets('6. fallback returns after list changes back to empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _AvatarHost(initialUrls: ['https://example.com/avatar.png']),
      );

      expect(find.byKey(const Key('fallback-icon')), findsNothing);

      await tester.tap(find.text('set-empty'));
      await tester.pump();

      expect(find.byKey(const Key('fallback-icon')), findsOneWidget);
    });
  });
}
