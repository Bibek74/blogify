import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'add_screen.dart';
import 'favourite_screen.dart';
import 'profile.dart';

class BottomNavScreen extends StatefulWidget {
  final bool showLoginSuccessPopup;

  const BottomNavScreen({super.key, this.showLoginSuccessPopup = false});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  int _homeRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showLoginSuccessPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        BuildContext? successDialogContext;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            successDialogContext = dialogContext;
            return AlertDialog(
              title: const Text('Success'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text('Login successful!'),
                ],
              ),
            );
          },
        ).then((_) {
          successDialogContext = null;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          final dialogContext = successDialogContext;
          if (dialogContext != null &&
              dialogContext.mounted &&
              Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screens = [
      HomeScreen(refreshTrigger: _homeRefreshToken),
      AddScreen(
        onPostCreated: () {
          setState(() {
            _homeRefreshToken++;
            _currentIndex = 0;
          });
        },
      ),
      const FavouriteScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.65,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favourite',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
