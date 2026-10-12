import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'screens/splash_screen.dart';

// Background/Terminated state me notification handle karne ke liye top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background Message Received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

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

  // Background FCM messaging handler set karein
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Unity Ads Initialization
  UnityAds.init(
    gameId: '800382914',
    testMode: true,
    onComplete: () => debugPrint('Unity Ads Initialized Successfully'),
    onFailed: (error, message) => debugPrint('Unity Ads Init Failed: $error $message'),
  );

  runApp(const CompeteMeApp());
}

class CompeteMeApp extends StatefulWidget {
  const CompeteMeApp({super.key});

  @override
  State<CompeteMeApp> createState() => _CompeteMeAppState();
}

class _CompeteMeAppState extends State<CompeteMeApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Notification permission request (Android 13+ & iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM token fetch karein
      String? token = await messaging.getToken();
      debugPrint("========== FCM TOKEN ==========");
      debugPrint(token);
      debugPrint("===============================");

      if (token != null) {
        _saveTokenToFirestore(token);
      }

      // Token refresh listener
      messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });

      // Foreground notification listener (App khuli ho tab)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground Message: ${message.notification?.title}");
      });
    }
  }

  // Token ko Firestore database me store karne ka function
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      await FirebaseFirestore.instance.collection('device_tokens').doc(token).set({
        'fcmToken': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("FCM Token saved to Firestore");
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompeteMe Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF1A237E),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          elevation: 0,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
