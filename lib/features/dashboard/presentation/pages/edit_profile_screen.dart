import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
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
            ],
          ),
        ),
      ),
    );
  }
}
