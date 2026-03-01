import 'package:blogify/core/providers/profile_provider.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/app/theme/theme_mode_provider.dart';
import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/widgets/smart_network_avatar.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/edit_profile_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/my_blogs_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _myBlogCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
    Future.microtask(_loadMyBlogCount);
  }

  Future<void> _loadMyBlogCount() async {
    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();
      if (token == null || token.isEmpty) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: ApiEndpoints.connectionTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final response = await dio.get(ApiEndpoints.postsMy);
      final data = response.data;

      if (data is! Map<String, dynamic> || data['success'] != true) return;

      final result = data['result'];
      int count = 0;

      if (result is Map<String, dynamic>) {
        final nestedPosts = result['posts'];
        if (nestedPosts is List) {
          count = nestedPosts.length;
        }
      } else if (result is List) {
        count = result.length;
      }

      if (!mounted) return;
      setState(() {
        _myBlogCount = count;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(userSessionServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    final state = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);

    final name = session.getCurrentUserFullName() ?? "User";
    final email = session.getCurrentUserEmail() ?? "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.tertiaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      SmartNetworkAvatar(
                        radius: 55,
                        backgroundColor: theme.colorScheme.surface,
                        imageUrls: ApiEndpoints.resolveMediaUrlCandidates(
                          state.imageUrl,
                        ),
                        fallback: Icon(
                          Icons.person,
                          size: 55,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: state.loading
                              ? null
                              : () => _showPicker(context, controller),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_myBlogCount blogs published',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _profileActionCard(
              context,
              icon: Icons.article_outlined,
              title: 'My blogs',
              subtitle: '$_myBlogCount blogs',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBlogsScreen()),
                );
                await _loadMyBlogCount();
              },
            ),
            _profileActionCard(
              context,
              icon: Icons.edit_outlined,
              title: 'Edit profile',
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );

                if (updated == true && mounted) {
                  setState(() {});
                }
              },
            ),
            _profileActionCard(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notification settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings coming soon'),
                  ),
                );
              },
            ),
            _profileActionCard(
              context,
              icon: Icons.lock_outline,
              title: 'Privacy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon')),
                );
              },
            ),
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                title: const Text('Dark mode'),
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).setDarkMode(value);
                },
              ),
            ),
            if (state.loading) ...[
              const SizedBox(height: 4),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text("Uploading..."),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);

                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout != true) return;

                await session.clearSession();
                ref.read(profileProvider.notifier).clear();
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showPicker(BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Take photo"),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from gallery"),
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
}
