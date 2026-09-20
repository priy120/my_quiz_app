import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _forceNavigateNext();
  }

  Future<void> _forceNavigateNext() async {
    // Hard 2-second delay for splash animation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Widget targetScreen = const LoginScreen();

    try {
      // Safe check with 1-second timeout limit
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 1));

      if (user != null) {
        targetScreen = const HomeScreen();
      }
    } catch (e) {
      debugPrint("Auth check skipped or failed: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 70,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CompeteMe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rojgar With Ankit Inspired Learning Portal',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ],
        ),
      ),
    );
  }
}
