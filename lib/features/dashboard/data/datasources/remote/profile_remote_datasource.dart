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

    if (token == null || token.isEmpty) return null;

    final res = await _dio.get(
      ApiEndpoints.profileMe,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    // backend response: { success: true, result: { profileImage: ... } }
    final profilePath = (res.data['result']?['profileImage'] ?? '') as String;
    if (profilePath.isEmpty) return null;

    // stored like "/public/item_photos/xxx.jpg"
    if (profilePath.startsWith('http')) return profilePath;

    return '${ApiEndpoints.serverUrl}$profilePath';
  }

  Future<String> uploadProfilePicture(File file) async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    final formData = FormData.fromMap({
      'profileImage': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.put(
      ApiEndpoints.profileUploadImage,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final profilePath = (response.data['result']?['profileImage'] ?? '') as String;
    if (profilePath.isEmpty) {
      throw Exception('Profile image upload failed.');
    }

    if (profilePath.startsWith('http')) return profilePath;
    return '${ApiEndpoints.serverUrl}$profilePath';
  }
}
