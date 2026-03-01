import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/home_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MyBlogsScreen extends ConsumerStatefulWidget {
  const MyBlogsScreen({super.key});

  @override
  ConsumerState<MyBlogsScreen> createState() => _MyBlogsScreenState();
}

class _MyBlogsScreenState extends ConsumerState<MyBlogsScreen> {
  late Future<List<HomePost>> _myPostsFuture;

  @override
  void initState() {
    super.initState();
    _myPostsFuture = _fetchMyPosts();
  }

  Future<List<HomePost>> _fetchMyPosts() async {
    final session = ref.read(userSessionServiceProvider);
    final token = await session.getToken();

    if (token == null || token.isEmpty) {
      await _handleSessionExpired();
      return const <HomePost>[];
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    try {
      final response = await dio.get(ApiEndpoints.postsMy);
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response from server.');
      }

      final success = data['success'] == true;
      if (!success) {
        final message =
            data['message']?.toString() ?? 'Failed to fetch your posts.';
        throw Exception(message);
      }

      final result = data['result'];
      List<dynamic> rawPosts = const [];

      if (result is Map<String, dynamic>) {
        final nestedPosts = result['posts'];
        if (nestedPosts is List) {
          rawPosts = nestedPosts;
        }
      } else if (result is List) {
        rawPosts = result;
      }

      return rawPosts
          .whereType<Map>()
          .map((item) => HomePost.fromJson(item.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return const <HomePost>[];
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw Exception(
          data['message']?.toString() ?? 'Failed to fetch your posts.',
        );
      }

      throw Exception('Failed to fetch your posts.');
    }
  }

  Future<void> _reloadPosts() async {
    setState(() {
      _myPostsFuture = _fetchMyPosts();
    });

    await _myPostsFuture;
  }

  Future<Dio?> _buildAuthorizedDio() async {
    final token = await ref.read(userSessionServiceProvider).getToken();
    if (token == null || token.isEmpty) {
      await _handleSessionExpired();
      return null;
    }

    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  Future<void> _deletePost(HomePost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete blog'),
        content: const Text('Are you sure you want to delete this blog?'),
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

    final dio = await _buildAuthorizedDio();
    if (dio == null) return;

    try {
      final response = await dio.delete(ApiEndpoints.postDelete(post.id));
      final data = response.data;
      final success = data is Map<String, dynamic>
          ? data['success'] == true
          : false;

      if (!success) {
        final message = data is Map<String, dynamic>
            ? data['message']?.toString() ?? 'Failed to delete blog.'
            : 'Failed to delete blog.';
        throw Exception(message);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blog deleted successfully.')),
      );
      await _reloadPosts();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e, 'Failed to delete blog.')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showEditDialog(HomePost post) async {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);

    final updatedData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit blog'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 8,
                minLines: 4,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = contentController.text.trim();

              if (title.length < 3 || description.isEmpty) {
                return;
              }

              Navigator.pop(context, {'title': title, 'content': description});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      titleController.dispose();
      contentController.dispose();
    });

    if (updatedData == null) return;
    final updatedTitle = (updatedData['title'] ?? '').trim();
    final updatedContent = (updatedData['content'] ?? '').trim();

    if (updatedTitle.isEmpty || updatedContent.isEmpty) return;
    if (updatedTitle == post.title.trim() &&
        updatedContent == post.content.trim()) {
      return;
    }

    final dio = await _buildAuthorizedDio();
    if (dio == null) return;

    try {
      final response = await dio.put(
        ApiEndpoints.postUpdate(post.id),
        data: {'title': updatedTitle, 'content': updatedContent},
      );

      final data = response.data;
      final success = data is Map<String, dynamic>
          ? data['success'] == true
          : false;

      if (!success) {
        final message = data is Map<String, dynamic>
            ? data['message']?.toString() ?? 'Failed to update blog.'
            : 'Failed to update blog.';
        throw Exception(message);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blog updated successfully.')),
      );
      await _reloadPosts();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e, 'Failed to update blog.')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleSessionExpired() async {
    final session = ref.read(userSessionServiceProvider);
    await session.clearSession();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please login again.')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
      (_) => false,
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserId = ref
        .read(userSessionServiceProvider)
        .getCurrentUserId();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Blog Studio',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Manage, edit and refine your stories',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadPosts,
        child: FutureBuilder<List<HomePost>>(
          future: _myPostsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            snapshot.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final posts = snapshot.data ?? const <HomePost>[];

            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No blogs found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
         
                                        'Publish your first blog from the Add tab.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.4,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.library_books_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${posts.length} blogs published',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap any blog to read, edit or remove',
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
                ...posts.map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PostCard(
                      title: post.title,
                      excerpt: post.content,
                      imageUrl: post.imageUrl,
                      author: post.authorName,
                      authorImageUrl: post.authorImageUrl,
                      authorRole: post.authorRole,
                      date: _formatDate(post.date),
                      likes: post.likesCount,
                      isLiked: post.isLikedBy(currentUserId),
                      onReadMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(post: post),
                          ),
                        );
                      },
                      onFavouriteTap: () {},
                      footer: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditDialog(post),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _deletePost(post),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            label: Text(
                              'Delete',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
