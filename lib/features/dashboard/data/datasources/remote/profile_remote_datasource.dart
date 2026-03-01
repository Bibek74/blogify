import 'dart:io';
import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSource {
  final Dio _dio;
  final UserSessionService _session;

  ProfileRemoteDataSource(this._dio, this._session);

  String _authHeaderValue(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) return trimmed;
    return 'Bearer $trimmed';
  }

  String? _pickProfileImagePath(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final value = data.trim();
      return value.isEmpty ? null : value;
    }

    if (data is Map) {
      const candidateKeys = ['profileImage', 'profile_picture', 'avatar', 'image'];

      for (final key in candidateKeys) {
        final direct = data[key];
        final directPath = _pickProfileImagePath(direct);
        if (directPath != null && directPath.isNotEmpty) {
          return directPath;
        }
      }

      const nestedKeys = ['result', 'data', 'user', 'profile'];
      for (final key in nestedKeys) {
        final nested = data[key];
        final nestedPath = _pickProfileImagePath(nested);
        if (nestedPath != null && nestedPath.isNotEmpty) {
          return nestedPath;
        }
      }
    }

    return null;
  }

  // ✅ NEW: fetch saved profile picture from backend (persistence)
  Future<String?> fetchProfilePictureUrl() async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) return null;

    final res = await _dio.get(
      ApiEndpoints.profileMe,
      options: Options(
        headers: {'Authorization': _authHeaderValue(token)},
      ),
    );

    final profilePath = _pickProfileImagePath(res.data);
    if (profilePath == null || profilePath.isEmpty) return null;

    return ApiEndpoints.resolveMediaUrl(profilePath);
  }

  Future<String> uploadProfilePicture(File file) async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    final formData = FormData.fromMap({
      'profileImage': await MultipartFile.fromFile(file.path),
    });

    late final Response response;
    try {
      response = await _dio.put(
        ApiEndpoints.profileUploadImage,
        data: formData,
        options: Options(
          headers: {
            'Authorization': _authHeaderValue(token),
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? 'Failed to upload profile image.')
          : 'Failed to upload profile image.';
      throw Exception(message);
    }

    final profilePath = _pickProfileImagePath(response.data);
    if (profilePath == null || profilePath.isEmpty) {
      throw Exception('Profile image upload failed.');
    }

    final resolved = ApiEndpoints.resolveMediaUrl(profilePath);
    if (resolved == null || resolved.isEmpty) {
      throw Exception('Profile image URL is invalid.');
    }
    return resolved;
  }
}
