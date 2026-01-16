import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/login_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/button_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
 @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Check if user is already logged in
    final userSessionService = ref.read(userSessionServiceProvider);
    final isLoggedIn = userSessionService.isLoggedIn();

    if (isLoggedIn) {
      // Navigate to Dashboard if user is logged in
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavScreen()));
    } else {
      // Navigate to Onboarding if user is not logged in
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/image.png",
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              "Blogify",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F3A4D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}