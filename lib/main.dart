import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBgcjqhhLZMg7I8sAmJoh3c364giGMJr6w",
        appId: "1:295041120734:android:6177cffa261033dfd7454f",
        messagingSenderId: "295041120734",
        projectId: "competeme1",
      ),
    );
  } catch (e) {
    debugPrint("Firebase explicit init: $e");
  }

  runApp(const CompeteMeApp());
}

class CompeteMeApp extends StatelessWidget {
  const CompeteMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompeteMe Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF1A237E),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
