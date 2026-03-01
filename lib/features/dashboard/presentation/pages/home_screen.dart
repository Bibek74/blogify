import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/core/widgets/smart_network_avatar.dart';
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

  Future<void> _toggleLike(HomePost post) async {
    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please login again.')));
        }
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

      await dio.post(ApiEndpoints.postLikeUnlike(post.id));
      await _reloadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Discover Blogs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
                children: [
                  SizedBox(
                    height: emptyStateHeight,
                    child: const Center(child: Text('No posts found')),
                  ),
                ],
              );
            }

            if (filteredPosts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: emptyStateHeight,
                    child: const Center(
                      child: Text('No posts match your search'),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...filteredPosts.map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PostCard(
                      title: post.title,
                      excerpt: post.content,
                      imageUrl: post.imageUrl,
                      author: post.authorName,
                      authorImageUrl: post.authorImageUrl,
                      authorRole: post.authorRole,
                      date: _formatDate(post.date),
                      likes: post.likesCount,
                      isLiked: post.isLikedBy(_currentUserId),
                      onReadMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post),
                          ),
                        );
                      },
                      onFavouriteTap: () => _toggleLike(post),
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
  final VoidCallback onReadMore;
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
    required this.onReadMore,
    required this.onFavouriteTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(authorRole, style: theme.textTheme.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              excerpt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.45,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(authorRole, style: theme.textTheme.labelSmall),
                ),
                const SizedBox(width: 10),
                Text(
                  date,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onFavouriteTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isLiked
                              ? theme.colorScheme.error
                              : theme.iconTheme.color,
                        ),
                        const SizedBox(width: 6),
                        Text('$likes', style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                ),
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
