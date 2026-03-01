import 'dart:io';
import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/dashboard/data/datasources/remote/profile_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.serverUrl,
      connectTimeout: ApiEndpoints.connectionTimeout,
      receiveTimeout: ApiEndpoints.receiveTimeout,
    ),
  );
});

class ProfileState {
  final bool loading;
  final String? imageUrl;
  final String? error;

  const ProfileState({
    this.loading = false,
    this.imageUrl,
    this.error,
  });

  ProfileState copyWith({
    bool? loading,
    String? imageUrl,
    String? error,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      imageUrl: imageUrl ?? this.imageUrl,
      error: error,
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final dio = ref.read(dioProvider);
  final session = ref.read(userSessionServiceProvider);
  return ProfileController(dio, session);
});

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._dio, this._session) : super(const ProfileState());

  final Dio _dio;
  final UserSessionService _session;
  final ImagePicker _picker = ImagePicker();

  String _withCacheBuster(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;

    final params = Map<String, String>.from(parsed.queryParameters);
    params['v'] = DateTime.now().millisecondsSinceEpoch.toString();
    return parsed.replace(queryParameters: params).toString();
  }

  // ✅ NEW: load profile picture from backend (persistence)
  Future<void> loadProfile() async {
    try {
      final remote = ProfileRemoteDataSource(_dio, _session);
      final url = await remote.fetchProfilePictureUrl();
      if (url != null && url.isNotEmpty) {
        state = state.copyWith(imageUrl: _withCacheBuster(url));
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> pickAndUpload(ImageSource source) async {
    state = state.copyWith(loading: true, error: null);

    try {
      // Camera permission only when using camera
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          state = state.copyWith(
            loading: false,
            error: "Camera permission denied",
          );
          return;
        }
      }

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (picked == null) {
        state = state.copyWith(loading: false);
        return;
      }

      final file = File(picked.path);

      final remote = ProfileRemoteDataSource(_dio, _session);
      final url = await remote.uploadProfilePicture(file);

      state = state.copyWith(
        loading: false,
        imageUrl: _withCacheBuster(url),
      );
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }

      state = state.copyWith(
        loading: false,
        error: message,
      );
    }
  }

  // ✅ NEW: clear local state on logout
  void clear() {
    state = const ProfileState();
  }
}
