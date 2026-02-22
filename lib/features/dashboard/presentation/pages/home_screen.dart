import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(Icons.image, size: 40, color: Colors.grey[500]),
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
                    style: const TextStyle(color: Colors.black87, height: 1.25),
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
                          Text(authorRole, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 18, color: Colors.redAccent),
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

  Future<void> _toggleLike(HomePost post) async {
    try {
      final session = ref.read(userSessionServiceProvider);
      final token = await session.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login again.')),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: SizedBox(
          height: 42,
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, color: Colors.black45),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
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
                          style: const TextStyle(color: Colors.redAccent),
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

            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('No posts found')),
                  ),
                ],
              );
            }

            if (filteredPosts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('No posts match your search')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: filteredPosts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return PostCard(
                  title: post.title,
                  excerpt: post.content,
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
                );
              },
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
      authorName: user?['name']?.toString() ?? 'Unknown',
      authorImageUrl: _resolveImageUrl(user?['profileImage']?.toString()),
      authorRole: 'blogger',
      date: json['date']?.toString(),
      likesCount: likes is List ? likes.length : 0,
      likedUserIds: likedUserIds,
    );
  }

  static String? _resolveImageUrl(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) return null;
    if (profileImage.startsWith('http')) return profileImage;
    return '${ApiEndpoints.serverUrl}$profileImage';
  }

  bool isLikedBy(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return likedUserIds.contains(userId);
  }
}

class PostCard extends StatelessWidget {
  final String title;
  final String excerpt;
  final String author;
  final String? authorImageUrl;
  final String authorRole;
  final String date;
  final int likes;
  final bool isLiked;
  final VoidCallback onReadMore;
  final VoidCallback onFavouriteTap;

  const PostCard({
    super.key,
    required this.title,
    required this.excerpt,
    required this.author,
    required this.authorImageUrl,
    required this.authorRole,
    required this.date,
    required this.likes,
    required this.isLiked,
    required this.onReadMore,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: authorImageUrl != null && authorImageUrl!.isNotEmpty
                          ? NetworkImage(authorImageUrl!)
                          : null,
                      child: (authorImageUrl == null || authorImageUrl!.isEmpty)
                          ? Text(
                              author.isNotEmpty ? author[0] : '?',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              excerpt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, height: 1.3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onReadMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EB1FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Read more',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onFavouriteTap,
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('$likes', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.bookmark_border,
                  size: 18,
                  color: Colors.black54,
                ),
              ],
            ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Blog Details'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
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
                  CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        post.authorImageUrl != null && post.authorImageUrl!.isNotEmpty
                        ? NetworkImage(post.authorImageUrl!)
                        : null,
                    child: (post.authorImageUrl == null || post.authorImageUrl!.isEmpty)
                        ? Text(
                            post.authorName.isNotEmpty ? post.authorName[0] : '?',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
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
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(post.date),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.favorite_border, size: 18, color: Colors.redAccent),
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
