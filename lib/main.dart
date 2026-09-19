import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Cookie Manager for keeping Google Login Session active
  final WebViewCookieManager cookieManager = WebViewCookieManager();
  cookieManager.setCookie(
    const WebViewCookie(
      name: 'auth_session',
      value: 'active',
      domain: 'letscompeteme.blogspot.com',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompeteMe Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
