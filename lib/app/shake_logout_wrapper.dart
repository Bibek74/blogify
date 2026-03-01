import 'package:blogify/core/providers/profile_provider.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/app/app_navigator_key.dart';
import 'package:blogify/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake_gesture/shake_gesture.dart';

class ShakeLogoutWrapper extends ConsumerStatefulWidget {
  const ShakeLogoutWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShakeLogoutWrapper> createState() => _ShakeLogoutWrapperState();
}

class _ShakeLogoutWrapperState extends ConsumerState<ShakeLogoutWrapper> {
  DateTime? _lastHandledAt;
  bool _isHandlingShake = false;

  Future<void> _onShakeDetected() async {
    if (!mounted || _isHandlingShake) return;

    final now = DateTime.now();
    final lastHandledAt = _lastHandledAt;
    if (lastHandledAt != null &&
        now.difference(lastHandledAt) < const Duration(seconds: 2)) {
      return;
    }

    final session = ref.read(userSessionServiceProvider);
    if (!session.isLoggedIn()) return;

    final navigatorContext = appNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    _isHandlingShake = true;
    _lastHandledAt = now;

    try {
      final shouldLogout = await showDialog<bool>(
        context: navigatorContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Shake detected. Logout now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        await session.clearSession(preserveForBiometric: true);
        ref.read(profileProvider.notifier).clear();

        final navigatorState = appNavigatorKey.currentState;
        navigatorState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      _isHandlingShake = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShakeGesture(onShake: _onShakeDetected, child: widget.child);
  }
}
