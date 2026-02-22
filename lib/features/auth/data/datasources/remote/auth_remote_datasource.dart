import 'package:blogify/core/api/api_client.dart';
import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/data/datasources/auth_datasource.dart';
import 'package:blogify/features/auth/data/models/auth_api_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  @override
  Future<AuthApiModel?> getUserById(String authId) {
    // TODO: implement getUserById
    throw UnimplementedError();
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.data['success'] == true) {
      final token = response.data['token'] as String?;
      if (token == null || token.isEmpty) return null;

      // Get user data from response
      final userData = response.data['data'] as Map<String, dynamic>?;
      if (userData == null) return null;

      final userId = userData['_id']?.toString();
      if (userId == null) return null;

      final fullName = userData['name']?.toString() ?? '';
      final userEmail = userData['email']?.toString() ?? email;
      final username = userEmail.split('@').first;

      // Save token
      await _userSessionService.saveToken(token);

      // Create user object
      final user = AuthApiModel(
        id: userId,
        fullName: fullName,
        username: username,
        email: email,
        password: null,
      );

      // Save session locally
      await _userSessionService.saveUserSession(
        userId: userId,
        email: userEmail,
        fullName: fullName,
        username: username,
      );

      return user;
    }

    return null;
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerRegister,
      data: user.toJson(),
    );

    // Check if the response indicates success
    final success = response.data['success'] ?? false;
    
    if (success == false) {
      // Backend returned success: false - throw error immediately
      final message = response.data['message'] ?? 'Registration failed';
      throw Exception(message);
    }
    
    // User successfully registered.
    // Do not create local session here; user must login first.
    return user;
  }
}
