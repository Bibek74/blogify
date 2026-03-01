import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences instance provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// UserSessionService provider
final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserSessionService(prefs: prefs);
});

class UserSessionService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for storing user data
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyUserPhoneNumber = 'user_phone_number';
  static const String _keyToken = 'auth_token';
  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricEmail = 'biometric_email';
  static const String _keyBiometricPassword = 'biometric_password';

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  String _normalizeToken(String token) {
    final trimmed = token.trim();
    const bearerPrefix = 'Bearer ';
    if (trimmed.toLowerCase().startsWith(bearerPrefix.toLowerCase())) {
      return trimmed.substring(bearerPrefix.length).trim();
    }
    return trimmed;
  }

  // Save user session after login
  Future<void> saveUserSession({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
    String? username,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setBool(_keyOnboardingSeen, true);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserFullName, fullName);
    if (phoneNumber != null) {
      await _prefs.setString(_keyUserPhoneNumber, phoneNumber);
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  bool hasSeenOnboarding() {
    return _prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_keyOnboardingSeen, true);
  }

  bool isBiometricEnabled() {
    return _prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricEnabled, enabled);
  }

  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _keyBiometricEmail, value: email.trim());
    await _secureStorage.write(key: _keyBiometricPassword, value: password);
  }

  Future<({String email, String password})?> getBiometricCredentials() async {
    final email = await _secureStorage.read(key: _keyBiometricEmail);
    final password = await _secureStorage.read(key: _keyBiometricPassword);

    if (email == null || email.trim().isEmpty) return null;
    if (password == null || password.isEmpty) return null;

    return (email: email.trim(), password: password);
  }

  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _keyBiometricEmail);
    await _secureStorage.delete(key: _keyBiometricPassword);
  }

  Future<bool> hasBiometricQuickLoginData() async {
    final token = await getToken();
    final userId = getCurrentUserId();
    final email = getCurrentUserEmail();
    final fullName = getCurrentUserFullName();

    return token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty &&
        email != null &&
        email.isNotEmpty &&
        fullName != null &&
        fullName.isNotEmpty;
  }

  Future<void> restoreSessionFromBiometric() async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setBool(_keyOnboardingSeen, true);
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _prefs.getString(_keyUserId);
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _prefs.getString(_keyUserEmail);
  }

  // Get current user full name
  String? getCurrentUserFullName() {
    return _prefs.getString(_keyUserFullName);
  }

  // Get current user phone number
  String? getCurrentUserPhoneNumber() {
    return _prefs.getString(_keyUserPhoneNumber);
  }

  // Save token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: _normalizeToken(token));
  }

  // Get token
  Future<String?> getToken() async {
    final token = await _secureStorage.read(key: _keyToken);
    if (token == null || token.trim().isEmpty) return null;
    return _normalizeToken(token);
  }

  // Clear user session (logout)
  Future<void> clearSession({bool preserveForBiometric = false}) async {
    if (preserveForBiometric && isBiometricEnabled()) {
      await _prefs.setBool(_keyIsLoggedIn, false);
      return;
    }

    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserFullName);
    await _prefs.remove(_keyUserPhoneNumber);
    await _secureStorage.delete(key: _keyToken);
  }
}
