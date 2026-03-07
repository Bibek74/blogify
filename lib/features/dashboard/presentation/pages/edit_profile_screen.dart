import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/providers/profile_provider.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/core/widgets/smart_network_avatar.dart';
import 'package:blogify/features/auth/presentation/pages/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
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

    final password = await _promptDeletionPassword();
    if (password == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();
      final userId = session.getCurrentUserId();
      final email = session.getCurrentUserEmail();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      if (email == null || email.trim().isEmpty) {
        throw Exception('Unable to verify password. Please login again.');
      }

      final passwordVerified = await _verifyDeletePassword(
        email: email.trim(),
        password: password,
      );

      if (!passwordVerified) {
        throw Exception('Incorrect password. Account was not deleted.');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.serverUrl,
          connectTimeout: ApiEndpoints.connectionTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {'Authorization': 'Bearer $token', 'x-auth-token': token},
        ),
      );

      final response = await _deleteAccountWithFallback(
        dio,
        userId: userId,
        password: password,
      );
      final data = response.data;
      final success = data['success'] != false;

      if (!success) {
        final message =
            data['message']?.toString() ?? 'Failed to delete account.';
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
    required String password,
  }) async {
    final payload = {
      'password': password,
      'currentPassword': password,
      'confirmPassword': password,
    };

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
        return await dio.delete(endpoint, data: payload);
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

  Future<String?> _promptDeletionPassword() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirm your password'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setStateDialog(() {
                          obscure = !obscure;
                        });
                      },
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    final valid = formKey.currentState?.validate() ?? false;
                    if (valid) {
                      Navigator.of(dialogContext).pop(controller.text.trim());
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final valid = formKey.currentState?.validate() ?? false;
                    if (!valid) return;
                    Navigator.of(dialogContext).pop(controller.text.trim());
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    return password;
  }

  Future<bool> _verifyDeletePassword({
    required String email,
    required String password,
  }) async {
    final verifier = Dio(
      BaseOptions(
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
      ),
    );

    try {
      final response = await verifier.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.customerLogin}',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return false;

      final success = data['success'] == true;
      final token = data['token']?.toString();

      return success && token != null && token.isNotEmpty;
    } on DioException {
      return false;
    }
  }

  void _showPicker(BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.read(userSessionServiceProvider);
    final profileState = ref.watch(profileProvider);
    final profileController = ref.read(profileProvider.notifier);
    final displayName = _nameController.text.trim().isEmpty
        ? (session.getCurrentUserFullName() ?? 'User')
        : _nameController.text.trim();
    final displayEmail = _emailController.text.trim().isEmpty
        ? (session.getCurrentUserEmail() ?? '')
        : _emailController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.tertiaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      SmartNetworkAvatar(
                        radius: 52,
                        backgroundColor: theme.colorScheme.surface,
                        imageUrls: ApiEndpoints.resolveMediaUrlCandidates(
                          profileState.imageUrl,
                        ),
                        fallback: Icon(
                          Icons.person,
                          size: 54,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                        ),
                      ),
                      Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: profileState.loading
                              ? null
                              : () => _showPicker(context, profileController),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (displayEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: profileState.loading
                            ? null
                            : () => profileController.pickAndUpload(
                                ImageSource.gallery,
                              ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                      OutlinedButton.icon(
                        onPressed: profileState.loading
                            ? null
                            : () => profileController.pickAndUpload(
                                ImageSource.camera,
                              ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                  if (profileState.loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (profileState.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      profileState.error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Account details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Save changes'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_isSaving || _isDeleting)
                    ? null
                    : _confirmAndDeleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(_isDeleting ? 'Deleting...' : 'Delete account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
