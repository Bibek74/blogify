import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/home_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FavouriteScreen extends ConsumerStatefulWidget {
  const FavouriteScreen({super.key});

  @override
  ConsumerState<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends ConsumerState<FavouriteScreen> {
  late Future<List<HomePost>> _favouritePostsFuture;
  String? _currentUserId;
  final Map<String, bool> _likedOverrides = <String, bool>{};
  final Map<String, int> _likeCountOverrides = <String, int>{};

  @override
  void initState() {
    super.initState();
    _currentUserId = ref.read(userSessionServiceProvider).getCurrentUserId();
    _favouritePostsFuture = _fetchFavouritePosts();
  }

  Future<List<HomePost>> _fetchFavouritePosts() async {
    final session = ref.read(userSessionServiceProvider);
    final currentUserId = session.getCurrentUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      return const <HomePost>[];
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
      ),
    );

    final response = await dio.get(ApiEndpoints.postsAll);
    final data = response.data;
    final success = data['success'] == true;

    if (!success) {
      final message =
          data['message']?.toString() ?? 'Failed to fetch favourites';
      throw Exception(message);
    }

    final list = data['result'] as List<dynamic>? ?? const [];

    final posts = list
        .map((item) => HomePost.fromJson(item as Map<String, dynamic>))
      .where((post) => PostFavouritesStore.isFavourited(post.id))
        .toList();

    return posts;
  }

  Future<void> _reloadFavourites() async {
    setState(() {
      _favouritePostsFuture = _fetchFavouritePosts();
    });
    await _favouritePostsFuture;
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
        headers: {
          'Authorization': 'Bearer $token',
          'x-auth-token': token,
        },
      ),
    );
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

  Future<void> _openComments(HomePost post) async {
    final session = ref.read(userSessionServiceProvider);
    final userName =
        session.getCurrentUserFullName() ?? session.getCurrentUserEmail() ?? 'You';
    final token = await session.getToken();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCommentsBottomSheet(
        post: post,
        currentUserName: userName,
        authToken: token,
      ),
    );
  }

  Future<void> _toggleLike(HomePost post) async {
    final dio = await _buildAuthorizedDio();
    if (dio == null) return;

    final previousLiked = _isPostLiked(post);
    final previousCount = _postLikeCount(post);

    setState(() {
      _likedOverrides[post.id] = !previousLiked;
      final nextCount = previousLiked ? previousCount - 1 : previousCount + 1;
      _likeCountOverrides[post.id] = nextCount < 0 ? 0 : nextCount;
    });

    try {
      await dio.post(ApiEndpoints.postLikeUnlike(post.id));
    } on DioException catch (e) {
      setState(() {
        _likedOverrides[post.id] = previousLiked;
        _likeCountOverrides[post.id] = previousCount;
      });

      if (e.response?.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(_extractErrorMessage(e, 'Failed to update like.'))),
        );
      }
    } catch (_) {
      setState(() {
        _likedOverrides[post.id] = previousLiked;
        _likeCountOverrides[post.id] = previousCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update like.')));
      }
    }
  }

  void _toggleFavourite(HomePost post) {
    setState(() {
      PostFavouritesStore.toggle(post.id);
      _favouritePostsFuture = _fetchFavouritePosts();
    });
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

  bool _isPostLiked(HomePost post) {
    return _likedOverrides[post.id] ?? post.isLikedBy(_currentUserId);
  }

  int _postLikeCount(HomePost post) {
    return _likeCountOverrides[post.id] ?? post.likesCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double horizontalPadding = 20;
    const double cardRadius = 18;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Saved Blogs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _reloadFavourites,
        child: FutureBuilder<List<HomePost>>(
          future: _favouritePostsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  16,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(cardRadius),
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
                            snapshot.error.toString(),
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
                padding: const EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  16,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border_rounded,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No favourite posts found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap bookmark on Home posts to see them here.',
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
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
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
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${posts.length} favourites saved',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...posts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final post = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: FadeSlideIn(
                      duration: Duration(milliseconds: 260 + (index * 25)),
                      child: PostCard(
                        title: post.title,
                        excerpt: post.content,
                        imageUrl: post.imageUrl,
                        author: post.authorName,
                        authorImageUrl: post.authorImageUrl,
                        authorRole: post.authorRole,
                        date: _formatDate(post.date),
                        likes: _postLikeCount(post),
                        isLiked: _isPostLiked(post),
                        isFavourited: PostFavouritesStore.isFavourited(post.id),
                        onReadMore: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(post: post),
                            ),
                          );
                        },
                        onCommentTap: () => _openComments(post),
                        onLikeTap: () => _toggleLike(post),
                        onFavouriteTap: () => _toggleFavourite(post),
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
