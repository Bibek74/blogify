import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:blogify/core/providers/profile_provider.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';

class MockDio extends Mock implements Dio {}
class MockUserSessionService extends Mock implements UserSessionService {}

void main() {
  test('ProfileState: default values are correct', () {
    final state = ProfileState();

    expect(state.loading, false);
    expect(state.imageUrl, isNull);
    expect(state.error, isNull);
  });

  test('ProfileController.clear(): resets ProfileState', () {
    final dio = MockDio();
    final session = MockUserSessionService();

    final controller = ProfileController(dio, session);

    // Put controller into a non-default state
    controller.state = ProfileState(
      loading: true,
      imageUrl: 'https://example.com/img.png',
      error: 'Error happened',
    );

    controller.clear();

    expect(controller.state.loading, false);

    // Depending on your clear() implementation, imageUrl might become null or ''
    expect(controller.state.imageUrl, anyOf(isNull, ''));

    expect(controller.state.error, isNull);
  });
}
