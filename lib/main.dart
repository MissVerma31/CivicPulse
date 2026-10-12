import 'package:flutter/material.dart';
import 'screens/home/splash_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'screens/auth/authority_home_screen.dart';
import 'core/theme/app_theme.dart';
import 'screens/citizen/citizen_shell_screen.dart';

void main() {
  runApp(const CivicPulseApp());
}

class CivicPulseApp extends StatelessWidget {
  const CivicPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
      routes: {
        '/citizen-home': (context) => const CitizenShellScreen(),
        '/authority-home': (context) => const AuthorityHomeScreen(),
      },
    );
  }
}