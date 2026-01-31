import 'package:blogify/core/api/api_client.dart';
import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/data/datasources/auth_datasource.dart';
import 'package:blogify/features/auth/data/models/auth_api_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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

      // Decode JWT token
      final decodedToken = JwtDecoder.decode(token);

      // NOTE: backend must include one of these keys
      final userId = (decodedToken['id'] ?? decodedToken['_id'])?.toString();
      if (userId == null) return null;

      // ✅ Username only from token (or empty)
      final username = decodedToken['username']?.toString() ?? '';

      // Full name from local storage (if you stored it during register)
      final storedFullName = _userSessionService.getCurrentUserFullName();

      // Save token
      await _userSessionService.saveToken(token);

      // Create user object
      final user = AuthApiModel(
        id: userId,
        fullName: storedFullName ?? '',
        username: username,
        email: email,
        password: null,
      );

      // Save session locally
      await _userSessionService.saveUserSession(
        userId: userId,
        email: email,
        fullName: user.fullName,
        username: username, // keep this if your service supports it
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

    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final registeredUser = AuthApiModel.fromJson(data);

      // Save user data locally for future login
      await _userSessionService.saveUserSession(
        userId: registeredUser.id!,
        email: registeredUser.email,
        fullName: registeredUser.fullName,
        username: registeredUser.username,
      );

      return registeredUser;
    } else {
      throw Exception(response.data['message'] ?? 'Registration failed');
    }
  }
}
