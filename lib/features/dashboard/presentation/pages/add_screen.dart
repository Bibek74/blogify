import 'dart:io';

import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AddScreen extends ConsumerStatefulWidget {
  final VoidCallback? onPostCreated;

  const AddScreen({super.key, this.onPostCreated});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  static const int _maxTitleLength = 120;
  static const int _maxDescriptionLength = 5000;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
    });
  }

  Future<void> _submitPost() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();

      if (token == null || token.isEmpty) {
        await _handleSessionExpired();
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: ApiEndpoints.connectionTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      await _createPost(dio);

      if (!mounted) return;

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post added successfully.')));

      widget.onPostCreated?.call();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }

      final message = _extractDioError(e);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleSessionExpired() async {
    final session = ref.read(userSessionServiceProvider);
    await session.clearSession();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please login again.')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  Future<void> _createPost(Dio dio) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final formPayload = <String, dynamic>{
      'title': title,
      'content': description,
    };

    if (_selectedImage != null) {
      formPayload['postImage'] = await MultipartFile.fromFile(
        _selectedImage!.path,
      );
    }

    final response = await dio.post(
      ApiEndpoints.postCreate,
      data: FormData.fromMap(formPayload),
    );

    final data = response.data;
    final success = data is Map<String, dynamic>
        ? data['success'] == true
        : false;

    if (!success) {
      final rawMessage = data is Map<String, dynamic> ? data['message'] : null;
      final message = data is Map<String, dynamic>
          ? _toFriendlyMessage(rawMessage) ?? 'Failed to create post.'
          : 'Failed to create post.';
      throw Exception(message);
    }
  }

  String? _toFriendlyMessage(dynamic value) {
    if (value == null) return null;
    final text = value.toString();

    if (text.contains('Content is too long')) {
      return 'Description must be $_maxDescriptionLength characters or less.';
    }

    if (text.contains('Title is too long')) {
      return 'Title must be $_maxTitleLength characters or less.';
    }

    if (text.contains('Title must be at least 3 characters')) {
      return 'Title must be at least 3 characters.';
    }

    if (text.contains('Content cannot be empty')) {
      return 'Description is required.';
    }

    return text;
  }

  String _extractDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final msg = data['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) {
        return statusCode != null ? '[$statusCode] $msg' : msg;
      }
      final error = data['error']?.toString();
      if (error != null && error.trim().isNotEmpty) {
        return statusCode != null ? '[$statusCode] $error' : error;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return statusCode != null ? '[$statusCode] ${data.trim()}' : data.trim();
    }

    final fallback = e.message?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return statusCode != null ? '[$statusCode] $fallback' : fallback;
    }

    return statusCode != null
        ? '[$statusCode] Failed to create post.'
        : 'Failed to create post.';
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
      alignLabelWithHint: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Blog',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make it memorable ✨',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                         
                    'Share your ideas with a beautiful and engaging blog post.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          theme,
                          label: 'Title',
                          hint: 'Enter a compelling title',
                          icon: Icons.title_rounded,
                        ),
                        maxLength: _maxTitleLength,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          if (value.trim().length > _maxTitleLength) {
                            return 'Title must be $_maxTitleLength characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 7,
                        decoration: _inputDecoration(
                          theme,
                          label: 'Description',
                          hint: 'Write your blog content here...',
                          icon: Icons.notes_rounded,
                        ),
                        maxLength: _maxDescriptionLength,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          if (value.trim().length > _maxDescriptionLength) {
                            return 'Description must be $_maxDescriptionLength characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cover image',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showImageSourceSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 190,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: theme.iconTheme.color?.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload image',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A good cover gets more clicks',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove image'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submitPost,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.publish_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Publish Blog'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
