import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/core/widgets/smart_network_avatar.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int refreshTrigger;

  const HomeScreen({super.key, this.refreshTrigger = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class PostCardAlt extends StatelessWidget {
  final String title;
  final String excerpt;
  final String author;
  final String authorRole;
  final String date;
  final int likes;

  const PostCardAlt({
    super.key,
    required this.title,
    required this.excerpt,
    required this.author,
    required this.authorRole,
    required this.date,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: theme.iconTheme.color?.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text(
                          author.isNotEmpty ? author[0] : '?',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author, style: const TextStyle(fontSize: 12)),
                          Text(
                            authorRole,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Text('$likes', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<HomePost>> _postsFuture;
  String? _currentUserId;
  String _searchQuery = '';
  final Map<String, bool> _likedOverrides = <String, bool>{};
  final Map<String, int> _likeCountOverrides = <String, int>{};

  @override
  void initState() {
    super.initState();
    _currentUserId = ref.read(userSessionServiceProvider).getCurrentUserId();
    _postsFuture = _fetchPosts();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _reloadPosts();
    }
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
    });
  }

  Future<List<HomePost>> _fetchPosts() async {
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
      final message = data['message']?.toString() ?? 'Failed to fetch posts';
      throw Exception(message);
    }

    final list = data['result'] as List<dynamic>? ?? const [];
    return list
        .map((item) => HomePost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _reloadPosts() async {
    setState(() {
      _postsFuture = _fetchPosts();
    });

    await _postsFuture;
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

  List<HomePost> _filterPosts(List<HomePost> posts) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return posts;

    return posts.where((post) {
      final title = post.title.toLowerCase();
      final content = post.content.toLowerCase();
      final author = post.authorName.toLowerCase();
      return title.contains(query) ||
          content.contains(query) ||
          author.contains(query);
    }).toList();
  }

  bool _isPostLiked(HomePost post) {
    return _likedOverrides[post.id] ?? post.isLikedBy(_currentUserId);
  }

  int _postLikeCount(HomePost post) {
    return _likeCountOverrides[post.id] ?? post.likesCount;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double horizontalPadding = 20;
    const double cardRadius = 18;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Discover Blogs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              4,
              horizontalPadding,
              14,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title, content or author',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadPosts,
        child: FutureBuilder<List<HomePost>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final posts = snapshot.data ?? const <HomePost>[];
            final filteredPosts = _filterPosts(posts);
            final emptyStateHeight = (MediaQuery.of(context).size.height * 0.35)
                .clamp(220.0, 360.0);

            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  SizedBox(height: emptyStateHeight * 0.16),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 34,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No posts yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pull to refresh and check for new stories.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (filteredPosts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  SizedBox(height: emptyStateHeight * 0.16),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 34,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No matching posts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try a different keyword for title, author, or content.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                24,
              ),
              children: [
                Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${filteredPosts.length} blogs ready to explore',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.trending_up_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...filteredPosts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final post = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
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
                              builder: (_) => PostDetailScreen(post: post),
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

class HomePost {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String authorName;
  final String? authorImageUrl;
  final String authorRole;
  final String? date;
  final int likesCount;
  final List<String> likedUserIds;

  const HomePost({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorName,
    required this.authorImageUrl,
    required this.authorRole,
    required this.date,
    required this.likesCount,
    required this.likedUserIds,
  });

  factory HomePost.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final likes = json['likes'];
    final likedUserIds = likes is List
        ? likes.map((item) => item.toString()).toList()
        : const <String>[];

    return HomePost(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      content: json['content']?.toString() ?? '',
      imageUrl: _resolvePostImageUrl(json),
      authorName: user?['name']?.toString() ?? 'Unknown',
      authorImageUrl: _resolveImageUrl(user?['profileImage']?.toString()),
      authorRole: 'blogger',
      date: json['date']?.toString(),
      likesCount: likes is List ? likes.length : 0,
      likedUserIds: likedUserIds,
    );
  }

  static String? _resolveImageUrl(String? profileImage) {
    return ApiEndpoints.resolveMediaUrl(profileImage);
  }

  static String? _resolvePostImageUrl(Map<String, dynamic> json) {
    final directCandidates = [
      json['image'],
      json['postImage'],
      json['coverImage'],
      json['thumbnail'],
      json['photo'],
    ];

    for (final candidate in directCandidates) {
      final path = _extractPath(candidate);
      if (path != null) return ApiEndpoints.resolveMediaUrl(path);
    }

    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      final path = _extractPath(images.first);
      if (path != null) return ApiEndpoints.resolveMediaUrl(path);
    }

    return null;
  }

  static String? _extractPath(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();

    if (value is Map) {
      const keys = ['url', 'path', 'image', 'secure_url'];
      for (final key in keys) {
        final raw = value[key];
        if (raw is String && raw.trim().isNotEmpty) {
          return raw.trim();
        }
      }
    }

    return null;
  }

  bool isLikedBy(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return likedUserIds.contains(userId);
  }
}

class PostCard extends StatelessWidget {
  final String title;
  final String excerpt;
  final String? imageUrl;
  final String author;
  final String? authorImageUrl;
  final String authorRole;
  final String date;
  final int likes;
  final bool isLiked;
  final bool isFavourited;
  final VoidCallback onReadMore;
  final VoidCallback onCommentTap;
  final VoidCallback onLikeTap;
  final VoidCallback onFavouriteTap;
  final Widget? footer;

  const PostCard({
    super.key,
    required this.title,
    required this.excerpt,
    required this.imageUrl,
    required this.author,
    required this.authorImageUrl,
    required this.authorRole,
    required this.date,
    required this.likes,
    required this.isLiked,
    required this.isFavourited,
    required this.onReadMore,
    required this.onCommentTap,
    required this.onLikeTap,
    required this.onFavouriteTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.iconTheme.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                SmartNetworkAvatar(
                  radius: 14,
                  imageUrls: ApiEndpoints.resolveMediaUrlCandidates(
                    authorImageUrl,
                  ),
                  fallback: Text(
                    author.isNotEmpty ? author[0] : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    author,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    authorRole,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              excerpt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onReadMore,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Read more'),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    date,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Tooltip(
                  message: 'Like',
                  child: IconButton(
                    onPressed: onLikeTap,
                    style: IconButton.styleFrom(
                      backgroundColor: isLiked
                          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
                          : Colors.transparent,
                    ),
                    icon: AnimatedScale(
                      scale: isLiked ? 1.12 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? Colors.red : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Comment',
                  child: IconButton(
                    onPressed: onCommentTap,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                    ),
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Tooltip(
                  message: 'Favourite',
                  child: IconButton(
                    onPressed: onFavouriteTap,
                    style: IconButton.styleFrom(
                      backgroundColor: isFavourited
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                    icon: AnimatedScale(
                      scale: isFavourited ? 1.1 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        isFavourited ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: isFavourited
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double beginOffsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.beginOffsetY = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * beginOffsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class PostComment {
  final String authorName;
  final String message;
  final DateTime createdAt;

  const PostComment({
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    String authorName = 'Unknown';
    if (user is Map<String, dynamic>) {
      authorName =
          user['name']?.toString() ??
          user['fullName']?.toString() ??
          user['username']?.toString() ??
          user['email']?.toString() ??
          'Unknown';
    } else {
      authorName =
          json['author']?.toString() ??
          json['name']?.toString() ??
          json['userName']?.toString() ??
          'Unknown';
    }

    final message =
        json['comment']?.toString() ??
        json['text']?.toString() ??
        json['content']?.toString() ??
        json['message']?.toString() ??
        '';

    final createdAtRaw =
        json['createdAt']?.toString() ??
        json['date']?.toString() ??
        json['timestamp']?.toString();

    final createdAt =
        createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

    return PostComment(
      authorName: authorName.trim().isEmpty ? 'Unknown' : authorName.trim(),
      message: message,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

class PostCommentsStore {
  PostCommentsStore._();

  static final Map<String, List<PostComment>> _commentsByPost = {};

  static List<PostComment> getComments(String postId) {
    final comments = _commentsByPost[postId] ?? const <PostComment>[];
    return List<PostComment>.from(comments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static void addComment({
    required String postId,
    required PostComment comment,
  }) {
    final comments = _commentsByPost.putIfAbsent(postId, () => <PostComment>[]);
    comments.add(comment);
  }
}

class PostFavouritesStore {
  PostFavouritesStore._();

  static final Set<String> _postIds = <String>{};

  static bool isFavourited(String postId) => _postIds.contains(postId);

  static void toggle(String postId) {
    if (_postIds.contains(postId)) {
      _postIds.remove(postId);
    } else {
      _postIds.add(postId);
    }
  }
}

class PostCommentsRepository {
  PostCommentsRepository._();

  static const List<String> _fetchPaths = [
    '/post/comments/{id}',
    '/post/comment/{id}',
    '/comments/{id}',
    '/comment/{id}',
  ];

  static const List<String> _addPaths = [
    '/post/comment/{id}',
    '/post/comments/{id}',
    '/comments/{id}',
    '/comment/{id}',
  ];

  static Future<List<PostComment>> fetchComments({
    required String postId,
    String? token,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
      ),
    );

    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (token != null && token.isNotEmpty) 'x-auth-token': token,
    };

    DioException? lastException;

    for (final pattern in _fetchPaths) {
      final path = pattern.replaceAll('{id}', postId);
      try {
        final response = await dio.get(path, options: Options(headers: headers));
        final rawComments = _extractCommentsFromResponse(response.data);
        final parsed = rawComments
            .whereType<Map>()
            .map((item) => PostComment.fromJson(item.cast<String, dynamic>()))
            .where((item) => item.message.trim().isNotEmpty)
            .toList();

        parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return parsed;
      } on DioException catch (e) {
        lastException = e;
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          continue;
        }
      }
    }

    if (lastException != null) throw lastException;
    return const <PostComment>[];
  }

  static Future<void> addComment({
    required String postId,
    required String message,
    String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required.');
    }

    final dio = Dio(
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

    DioException? lastException;

    for (final pattern in _addPaths) {
      final path = pattern.replaceAll('{id}', postId);
      final payloads = [
        {'comment': message},
        {'text': message},
        {'content': message},
      ];

      for (final payload in payloads) {
        try {
          final response = await dio.post(path, data: payload);
          if ((response.statusCode ?? 500) < 400) {
            return;
          }
        } on DioException catch (e) {
          lastException = e;
          if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
            continue;
          }
        }
      }
    }

    if (lastException != null) throw lastException;
    throw Exception('Failed to add comment.');
  }

  static List<dynamic> _extractCommentsFromResponse(dynamic data) {
    if (data is List) return data;

    if (data is Map<String, dynamic>) {
      final candidates = [
        data['comments'],
        data['result'],
        data['data'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;
        if (candidate is Map<String, dynamic>) {
          final nested = candidate['comments'];
          if (nested is List) return nested;
        }
      }
    }

    return const [];
  }
}

class PostCommentsBottomSheet extends StatefulWidget {
  final HomePost post;
  final String currentUserName;
  final String? authToken;

  const PostCommentsBottomSheet({
    super.key,
    required this.post,
    required this.currentUserName,
    required this.authToken,
  });

  @override
  State<PostCommentsBottomSheet> createState() => _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState extends State<PostCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<PostComment> _comments = const <PostComment>[];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final remote = await PostCommentsRepository.fetchComments(
        postId: widget.post.id,
        token: widget.authToken,
      );

      final local = PostCommentsStore.getComments(widget.post.id);
      final combined = [...remote, ...local]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _comments = combined;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _comments = PostCommentsStore.getComments(widget.post.id);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty || _isSubmitting) return;

    final localComment = PostComment(
      authorName: widget.currentUserName,
      message: message,
      createdAt: DateTime.now(),
    );

    PostCommentsStore.addComment(postId: widget.post.id, comment: localComment);

    setState(() {
      _isSubmitting = true;
      _comments = PostCommentsStore.getComments(widget.post.id);
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      await PostCommentsRepository.addComment(
        postId: widget.post.id,
        message: message,
        token: widget.authToken,
      );

      await _loadComments(showLoader: false);
    } catch (_) {
      // Keep locally saved comment when remote sync fails.
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatCommentTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_comments.length}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet. Be the first to comment.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.authorName,
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatCommentTime(comment.createdAt),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(comment.message, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSubmitting ? null : _submitComment,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  final HomePost post;

  const PostDetailScreen({super.key, required this.post});

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Blog Details'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SmartNetworkAvatar(
                    radius: 14,
                    imageUrls: ApiEndpoints.resolveMediaUrlCandidates(
                      post.authorImageUrl,
                    ),
                    fallback: Text(
                      post.authorName.isNotEmpty ? post.authorName[0] : '?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          post.authorRole,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(post.date),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text('${post.likesCount}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.content,
                style: const TextStyle(fontSize: 16, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
