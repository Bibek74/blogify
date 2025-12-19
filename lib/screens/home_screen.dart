import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PostCard(
            title: 'Please Start Writing Better Git Commits',
            excerpt:
                'I recently read a helpful article on Hashnode by Simon Egersand titled "Write Git Commit Messages Your Colleagues Will Love," and it inspired me to dive a little deeper into understanding what makes a Git commit good or bad.',
            author: 'New',
            authorRole: 'blogger',
            date: 'Jul 29, 2022',
            likes: 20,
          ),
          SizedBox(height: 16),
          PostCard(
            title: 'About criticism',
            excerpt:
                'Everybody is a critic. Every developer has both been on the receiving and the giving end of criticism. It is a vital part of our job, be it as code review, comments on social networks like this one or during a retrospective. So let us have a look at both sides of criticism:',
            author: 'Aman',
            authorRole: 'blogger',
            date: 'Jul 20, 2022',
            likes: 200,
          ),
          SizedBox(height: 16),
          PostCard(
            title: 'Learnable Design Patterns',
            excerpt:
                'Shared patterns make applications easier to maintain. This post briefly explores a few practical UI and code patterns I find useful.',
            author: 'Sam',
            authorRole: 'developer',
            date: 'Nov 2, 2022',
            likes: 78,
          ),
          SizedBox(height: 16),
          PostCard(
            title: 'Learnable MCV Patterns',
            excerpt:
                'Shared MVC patterns make applications easier to maintain. This post briefly explores a few practical UI and code patterns I find useful.',
            author: 'Sam',
            authorRole: 'developer',
            date: 'Nov 2, 2022',
            likes: 78,
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String title;
  final String excerpt;
  final String author;
  final String authorRole;
  final String date;
  final int likes;

  const PostCard({
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
                      child: Text(
                        author.isNotEmpty ? author[0] : '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authorRole,
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
                  onPressed: () {},
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
                    const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.redAccent,
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
