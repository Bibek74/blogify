import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.animateToPage(_page + 1,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildPage({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3F3F3F), Color(0xFF1F1F1F)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/icons/blogify_logo.png',
                    width: 45,
                    height: 45,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Blogify',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              // Bottom area (dots and buttons) handled by parent
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _buildPage(
                title: 'Welcome to Blogify',
                subtitle: 'Write, share and discover stories from creators.',
              ),
              _buildPage(
                title: 'Create Your Story',
                subtitle: 'Compose beautiful posts with images and markdown.',
              ),
              _buildPage(
                title: 'Join the Community',
                subtitle: 'Follow creators, comment and grow your audience.',
              ),
            ],
          ),
          // Top-right Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          // Bottom controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _page == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                    ),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                        onPressed: _next,
                        child: Text(_page < 2 ? 'Next' : 'Get started',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
