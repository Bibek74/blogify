import 'package:flutter_test/flutter_test.dart';

// Signup validator functions
String? validateName(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your name';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your email';
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Please enter a password';
  if (value.length < 6) return 'At least 6 characters required';
  return null;
}

String? validateConfirmPassword(String password, String? confirmValue) {
  if (confirmValue == null || confirmValue.isEmpty) {
    return 'Please confirm your password';
  }
  if (confirmValue != password) {
    return 'Passwords do not match';
  }
  return null;
}

void main() {
  test('Signup: returns error when name is empty', () {
    expect(
      validateName(''),
      'Please enter your name',
    );
  });

  test('Signup: returns error when email is invalid', () {
    expect(
      validateEmail('invalid.email'),
      'Please enter a valid email',
    );
  });

  test('Signup: returns error when password is less than 6 characters', () {
    expect(
      validatePassword('12345'),
      'At least 6 characters required',
    );
  });

  test('Signup: returns error when passwords do not match', () {
    expect(
      validateConfirmPassword('1234567', '7654321'),
      'Passwords do not match',
    );
  });

  test('Signup: returns null when all fields are valid', () {
    expect(validateName('John Doe'), isNull);
    expect(validateEmail('john@gmail.com'), isNull);
    expect(validatePassword('1234567'), isNull);
    expect(validateConfirmPassword('1234567', '1234567'), isNull);
  });
}
