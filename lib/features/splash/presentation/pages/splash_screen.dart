import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/login_screen.dart';
import 'package:blogify/features/dashboard/presentation/pages/button_navigation.dart';
import 'package:blogify/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final session = ref.read(userSessionServiceProvider);
      final hasSeenOnboarding = session.hasSeenOnboarding();
      final isBiometricEnabled = session.isBiometricEnabled();

      if (!hasSeenOnboarding) {
        if (isBiometricEnabled) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }

      if (!session.isLoggedIn()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      if (session.isBiometricEnabled()) {
        final authenticated = await _authenticateWithBiometrics();
        if (!mounted) return;

        if (!authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      );
    });
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();

      if (!canCheck || !supported) {
        return true;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue to Blogify',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0EB),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Blogify',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A3C33),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Read. Write. Inspire.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5B6662),
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E8B39)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
