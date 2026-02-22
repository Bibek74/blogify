import 'package:blogify/core/api/api_endpoint.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
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

  @override
  void initState() {
    super.initState();
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
      final message = data['message']?.toString() ?? 'Failed to fetch favourites';
      throw Exception(message);
    }

    final list = data['result'] as List<dynamic>? ?? const [];

    final posts = list
        .map((item) => HomePost.fromJson(item as Map<String, dynamic>))
        .where((post) => post.isLikedBy(currentUserId))
        .toList();

    return posts;
  }

  Future<void> _reloadFavourites() async {
    setState(() {
      _favouritePostsFuture = _fetchFavouritePosts();
    });
    await _favouritePostsFuture;
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
      await _reloadFavourites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
    final currentUserId = ref.read(userSessionServiceProvider).getCurrentUserId();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Favourite'),
        backgroundColor: Colors.white,
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

            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('No favourite posts found')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  title: post.title,
                  excerpt: post.content,
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