import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Configuration
  static const bool isPhysicalDevice = false;
  static const String _ipAddress = '192.168.1.78';
  static const int _port = 5000;

  // Base URLs
  static String get _host {
    if (isPhysicalDevice) return _ipAddress;
    if (kIsWeb || Platform.isIOS) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get serverUrl => 'http://$_host:$_port';
  static String get baseUrl => '$serverUrl/api';
  static String get mediaServerUrl => serverUrl;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String customers = '/customers';
  static const String customerLogin = '/auth/login';
  static const String customerRegister = '/auth/signup';
  static const String postsAll = '/post/all';
  static const String profileMe = '/api/profile/me';
  static const String profileUploadImage = '/api/profile/upload-image';
  static String postLikeUnlike(String postId) => '/post/like-unlike/$postId';

  static String customerById(String id) => '$baseUrl/$id';
  static String uploadProfilePicture(String id) => '$baseUrl/$id/profile-picture';
}
