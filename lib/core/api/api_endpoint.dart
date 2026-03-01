import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Configuration
  static const bool isPhysicalDevice = true;
  static const String _ipAddress = '192.168.254.53';
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

  static String? resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final raw = path.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final parsed = Uri.tryParse(raw);
      if (parsed != null) {
        var normalizedPath = parsed.path;
        if (normalizedPath.startsWith('/api/public/')) {
          normalizedPath = normalizedPath.replaceFirst(
            '/api/public/',
            '/public/',
          );
        } else if (normalizedPath.startsWith('/api/uploads/')) {
          normalizedPath = normalizedPath.replaceFirst(
            '/api/uploads/',
            '/uploads/',
          );
        } else if (normalizedPath.startsWith('/api/item_photos/')) {
          normalizedPath = normalizedPath.replaceFirst(
            '/api/item_photos/',
            '/item_photos/',
          );
        }

        final isLocalHost =
            parsed.host == 'localhost' ||
            parsed.host == '127.0.0.1' ||
            parsed.host == '10.0.2.2';

        final updatedPath = normalizedPath != parsed.path;

        if (isLocalHost || updatedPath) {
          final mediaBase = Uri.parse(mediaServerUrl);
          final normalized = parsed.replace(
            scheme: mediaBase.scheme,
            host: mediaBase.host,
            port: mediaBase.port,
            path: normalizedPath,
          );
          return normalized.toString();
        }
      }

      return raw;
    }

    var withLeadingSlash = raw.startsWith('/') ? raw : '/$raw';

    if (withLeadingSlash.startsWith('/api/public/')) {
      withLeadingSlash = withLeadingSlash.replaceFirst(
        '/api/public/',
        '/public/',
      );
    } else if (withLeadingSlash.startsWith('/api/uploads/')) {
      withLeadingSlash = withLeadingSlash.replaceFirst(
        '/api/uploads/',
        '/uploads/',
      );
    } else if (withLeadingSlash.startsWith('/api/item_photos/')) {
      withLeadingSlash = withLeadingSlash.replaceFirst(
        '/api/item_photos/',
        '/item_photos/',
      );
    }

    if (withLeadingSlash.startsWith('/public/')) {
      if (withLeadingSlash.startsWith('/public/uploads/')) {
        final uploadPath = withLeadingSlash.replaceFirst(
          '/public/uploads/',
          '/uploads/',
        );
        return '$mediaServerUrl$uploadPath';
      }
      return '$mediaServerUrl$withLeadingSlash';
    }

    if (withLeadingSlash.startsWith('/uploads/')) {
      return '$mediaServerUrl$withLeadingSlash';
    }

    return '$mediaServerUrl$withLeadingSlash';
  }

  static List<String> resolveMediaUrlCandidates(String? pathOrUrl) {
    final primary = resolveMediaUrl(pathOrUrl);
    if (primary == null || primary.isEmpty) return const [];

    final candidates = <String>[primary];
    final primaryUri = Uri.tryParse(primary);

    void addIfNew(String value) {
      if (value.isEmpty) return;
      if (!candidates.contains(value)) {
        candidates.add(value);
      }
    }

    void addPathVariant(String sourceSegment, String targetSegment) {
      if (!primary.contains(sourceSegment)) return;

      if (primaryUri != null && primaryUri.hasScheme) {
        final nextPath = primaryUri.path.replaceFirst(
          sourceSegment,
          targetSegment,
        );
        addIfNew(primaryUri.replace(path: nextPath).toString());
      } else {
        addIfNew(primary.replaceFirst(sourceSegment, targetSegment));
      }
    }

    void addBidirectionalVariants(String a, String b) {
      addPathVariant(a, b);
      addPathVariant(b, a);
    }

    addBidirectionalVariants('/public/uploads/', '/uploads/');
    addBidirectionalVariants('/api/public/uploads/', '/public/uploads/');
    addBidirectionalVariants('/api/uploads/', '/uploads/');
    addBidirectionalVariants('/api/public/uploads/', '/api/uploads/');

    addBidirectionalVariants('/public/item_photos/', '/item_photos/');
    addBidirectionalVariants(
      '/api/public/item_photos/',
      '/public/item_photos/',
    );
    addBidirectionalVariants('/api/item_photos/', '/item_photos/');
    addBidirectionalVariants('/api/public/item_photos/', '/api/item_photos/');

    final basename = primaryUri?.pathSegments.isNotEmpty == true
        ? primaryUri!.pathSegments.last
        : '';

    if (basename.isNotEmpty) {
      final baseUri = primaryUri != null && primaryUri.hasScheme
          ? primaryUri
          : Uri.parse(mediaServerUrl);

      addIfNew(baseUri.replace(path: '/public/uploads/$basename').toString());
      addIfNew(baseUri.replace(path: '/uploads/$basename').toString());
      addIfNew(
        baseUri.replace(path: '/api/public/uploads/$basename').toString(),
      );
      addIfNew(baseUri.replace(path: '/api/uploads/$basename').toString());
    }

    return candidates;
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String customers = '/customers';
  static const String customerLogin = '/auth/login';
  static const String customerRegister = '/auth/signup';
  static const String postsAll = '/post/all';
  static const String postsMy = '/post/my-posts';
  static const String postCreate = '/post/new';
  static const String profileMe = '/api/profile/me';
  static const String profileUpdate = '/api/profile/update-profile';
  static const String profileUploadImage = '/api/profile/upload-image';
  static String postLikeUnlike(String postId) => '/post/like-unlike/$postId';
  static String postUpdate(String postId) => '/post/update/$postId';
  static String postDelete(String postId) => '/post/delete-post/$postId';

  static String customerById(String id) => '$baseUrl/$id';
  static String uploadProfilePicture(String id) =>
      '$baseUrl/$id/profile-picture';
}
