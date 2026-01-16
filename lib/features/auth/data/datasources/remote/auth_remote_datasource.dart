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

class AuthRemoteDatasource implements IAuthRemoteDataSource{

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
      if (token != null) {
        // Decode JWT token to get user ID
        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['id'] as String;

        // Save token
        await _userSessionService.saveToken(token);

        // Try to get user data from local storage first
        final storedFullName = _userSessionService.getCurrentUserFullName();
        final storedPhoneNumber = _userSessionService.getCurrentUserPhoneNumber();

        // Create user object with stored data
        final user = AuthApiModel(
          id: userId,
          fullName: storedFullName ?? '', // Use stored data or empty string
          email: email,
          phoneNumber: storedPhoneNumber,
          password: null,
        );

        // Update stored session with latest info
        await _userSessionService.saveUserSession(
          userId: userId,
          email: email,
          fullName: user.fullName,
        );

        return user;
      }
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
        phoneNumber: registeredUser.phoneNumber,
      );

      return registeredUser;
    } else {
      throw Exception(response.data['message'] ?? 'Registration failed');
    }
  }
  
  
}