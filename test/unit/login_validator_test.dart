import 'package:flutter_test/flutter_test.dart';

// Simple validator functions for testing
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  return null;
}

void main() {
  test('Login: returns error when email is empty', () {
    expect(
      validateEmail(''),
      'Email is required',
    );
  });

  test('Login: returns error when password is empty', () {
    expect(
      validatePassword(''),
      'Password is required',
    );
  });

  test('Login: returns error when email is invalid', () {
    expect(
      validateEmail('invalid.email'),
      'Enter a valid email',
    );
  });

  test('Login: returns null when email and password are valid', () {
    expect(
      validateEmail('test@gmail.com'),
      isNull,
    );
    expect(
      validatePassword('1234567'),
      isNull,
    );
  });
}
