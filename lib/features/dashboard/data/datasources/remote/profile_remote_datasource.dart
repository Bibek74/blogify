import 'dart:io';
import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSource {
  final Dio _dio;
  final UserSessionService _session;

  ProfileRemoteDataSource(this._dio, this._session);

  // ✅ NEW: fetch saved profile picture from backend (persistence)
  Future<String?> fetchProfilePictureUrl() async {
    final token = await _session.getToken();
    final customerId = _session.getCurrentUserId();

    if (token == null || token.isEmpty) return null;
    if (customerId == null || customerId.isEmpty) return null;

    final res = await _dio.get(
      ApiEndpoints.customerById(customerId),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    // backend response: { success: true, data: customer }
    final profilePath = (res.data['data']['profilePicture'] ?? '') as String;
    if (profilePath.isEmpty) return null;

    // stored like "/public/item_photos/xxx.jpg"
    if (profilePath.startsWith('http')) return profilePath;

    return '${ApiEndpoints.serverUrl}$profilePath';
  }

  Future<String> uploadProfilePicture(File file) async {
    final token = await _session.getToken();
    final customerId = _session.getCurrentUserId();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }
    if (customerId == null || customerId.isEmpty) {
      throw Exception("UserId missing. Please login again.");
    }

    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.post(
      ApiEndpoints.uploadProfilePicture(customerId),
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data['data']['profilePictureUrl'] as String;
  }
}
