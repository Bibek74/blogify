import 'package:blogify/core/providers/profile_provider.dart';
import 'package:blogify/core/services/hive/hive_service.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';

class MockDio extends Mock implements Dio {}

class MockUserSessionService extends Mock implements UserSessionService {}

class MockHiveService extends Mock implements HiveService {}

class TestProfileController extends ProfileController {
  TestProfileController(super.dio, super.session);

  bool loadProfileCalled = false;
  bool clearCalled = false;
  ImageSource? lastPickedSource;

  @override
  Future<void> loadProfile() async {
    loadProfileCalled = true;
  }

  @override
  Future<void> pickAndUpload(ImageSource source) async {
    lastPickedSource = source;
  }

  @override
  void clear() {
    clearCalled = true;
    super.clear();
  }
}

void main() {
  testWidgets(
    'ProfileScreen: shows title, user info, opens picker sheet, and logout navigates to SignupScreen',
    (tester) async {
      final mockDio = MockDio();
      final mockSession = MockUserSessionService();
      final mockHiveService = MockHiveService();

      when(() => mockSession.getCurrentUserFullName()).thenReturn('Bibek Shah');
      when(
        () => mockSession.getCurrentUserEmail(),
      ).thenReturn('bbekshah789@gmail.com');

      when(() => mockSession.clearSession()).thenAnswer((_) async {});

      final testController = TestProfileController(mockDio, mockSession);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(mockDio),
            userSessionServiceProvider.overrideWithValue(mockSession),
            hiveServiceProvider.overrideWithValue(mockHiveService),

            profileProvider.overrideWith((ref) => testController),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Profile'), findsOneWidget);

      expect(find.text('Bibek Shah'), findsOneWidget);
      expect(find.text('bbekshah789@gmail.com'), findsOneWidget);

      expect(find.byIcon(Icons.person), findsOneWidget);

      expect(testController.loadProfileCalled, isTrue);

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);

      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(testController.lastPickedSource, ImageSource.gallery);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      verify(() => mockSession.clearSession()).called(1);
      expect(testController.clearCalled, isTrue);

      expect(find.byType(SignupScreen), findsOneWidget);
    },
  );
}
