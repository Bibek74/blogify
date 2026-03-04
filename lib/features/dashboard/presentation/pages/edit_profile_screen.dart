import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(userSessionServiceProvider);
    _nameController.text = session.getCurrentUserFullName() ?? '';
    _emailController.text = session.getCurrentUserEmail() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Name is required';
    if (text.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  Future<void> _saveProfile() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.serverUrl,
          connectTimeout: ApiEndpoints.connectionTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      final response = await _updateProfileWithFallback(dio, payload);
      final data = response.data;
      final success = data is Map<String, dynamic>
          ? data['success'] == true
          : false;

      if (!success) {
        final message = data is Map<String, dynamic>
            ? data['message']?.toString() ?? 'Failed to update profile.'
            : 'Failed to update profile.';
        throw Exception(message);
      }

      final currentUserId = session.getCurrentUserId() ?? '';
      final currentPhone = session.getCurrentUserPhoneNumber();
      await session.saveUserSession(
        userId: currentUserId,
        email: payload['email']!,
        fullName: payload['name']!,
        phoneNumber: currentPhone,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['message']?.toString() ?? 'Failed to update profile.'
          : 'Failed to update profile.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Response<dynamic>> _updateProfileWithFallback(
    Dio dio,
    Map<String, String> payload,
  ) async {
    final endpoints = [
      ApiEndpoints.profileUpdate,
      '/api/profile/update',
      '/api/profile/me',
    ];

    DioException? lastError;

    for (final endpoint in endpoints) {
      try {
        return await dio.put(endpoint, data: payload);
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        if (status != 404 && status != 405) {
          rethrow;
        }
      }
    }

    if (lastError != null) throw lastError;
    throw Exception('Profile update endpoint not found.');
  }

  Future<void> _confirmAndDeleteAccount() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();
      final userId = session.getCurrentUserId();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.serverUrl,
          connectTimeout: ApiEndpoints.connectionTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {
            'Authorization': 'Bearer $token',
            'x-auth-token': token,
          },
        ),
      );

      final response = await _deleteAccountWithFallback(dio, userId: userId);
      final data = response.data;
      final success = data is Map<String, dynamic>
          ? data['success'] != false
          : true;

      if (!success) {
        final message = data is Map<String, dynamic>
            ? data['message']?.toString() ?? 'Failed to delete account.'
            : 'Failed to delete account.';
        throw Exception(message);
      }

      await session.clearSession();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['message']?.toString() ?? 'Failed to delete account.'
          : 'Failed to delete account.';

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<Response<dynamic>> _deleteAccountWithFallback(
    Dio dio, {
    required String? userId,
  }) async {
    final endpoints = [
      '/api/profile/delete-account',
      '/api/profile/delete-profile',
      '/api/profile/me',
      if (userId != null && userId.isNotEmpty) '/customers/$userId',
      if (userId != null && userId.isNotEmpty) '/api/customers/$userId',
    ];

    DioException? lastError;

    for (final endpoint in endpoints) {
      try {
        return await dio.delete(endpoint);
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        if (status != 404 && status != 405) {
          rethrow;
        }
      }
    }

    if (lastError != null) throw lastError;
    throw Exception('Delete account endpoint not found.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_isSaving || _isDeleting)
                      ? null
                      : _confirmAndDeleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Delete account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
