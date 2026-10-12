import 'package:flutter/material.dart';
import '../../core/storage/token_storage.dart';
import '../auth/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      // Already have a valid session -- skip role selection entirely and
      // route straight to the correct dashboard based on stored role.
      final role = await TokenStorage.getRole();
      if (!mounted) return;
      if (role?.toUpperCase() == 'AUTHORITY') {
        Navigator.of(context).pushReplacementNamed('/authority-home');
      } else {
        Navigator.of(context).pushReplacementNamed('/citizen-home');
      }
    } else {
      // No session yet -- CHANGED: send to RoleSelectionScreen (Citizen
      // vs Authority) instead of straight to LoginScreen, so the login
      // screen knows which role to validate against after login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}