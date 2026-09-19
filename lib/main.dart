import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CompeteMe Mock Test',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A73E8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
