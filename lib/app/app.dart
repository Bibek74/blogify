import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/splash/presentation/pages/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'EverBlue',
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}