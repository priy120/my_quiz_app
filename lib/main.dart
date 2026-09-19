import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/app_theme.dart';
import 'services/blogger_service.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mock Test Portal',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _latestTests;

  @override
  void initState() {
    super.initState();
    _latestTests = BloggerService.fetchLatestTests();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Test Portal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.Yeh GitHub par base `main.dart` code ka breakdown aur workflow hai:

**1. Imports & Entry Point**
* `main()` function `QuizApp` widget ko run karta hai[cite: 1].
* Theme configurations (`AppTheme`) aur external data services (`BloggerService`) ko import kiya gaya hai[cite: 1].

**2. App Configuration (`QuizApp`)**
* `MaterialApp` setup kiya gaya hai jisme `debugShowCheckedModeBanner: false`, title `'Mock Test Portal'`, custom theme, aur home screen `HomeScreen()` assigned hai[cite: 1].

**3. Data Fetching & State (`_HomeScreenState`)**
* `initState()` ke andar `BloggerService.fetchLatestTests()` Call karke API/Blogger post list asynchronous tarike se `_latestTests` Future variable mein store hoti hai[cite: 1, 2].

**4. UI Structure (`HomeScreen`)**
* **AppBar:** Title dikhata hai `'Mock Test Portal'`[cite: 1, 2].
* **Banner Container:** Gradient background (Blue) ke saath poster/card jisme text hai: *"Prepare & Win Rewards"* aur *"Attempt Free Mock Tests & Earn Coins!"*[cite: 1, 2].
* **Section Title:** `'Latest Available Tests'`[cite: 1, 2].
* **FutureBuilder Execution:**
  * **Loading State:** `ConnectionState.waiting` par loading spinner (`CircularProgressIndicator`) dikhata hai[cite: 1, 2].
  * **Empty/No Data State:** Agar test list khali ho ya `hasData` na ho, toh card me text show hota hai: `"Abhi koi tests load nahi hue."`[cite: 1, 2].
  * **Data Loaded State:** Data milne par `ListView.builder` list render karta hai[cite: 2]. Har test ek `Card` aur `ListTile` mein aata hai jisme test title aur ek red **"Start"** `ElevatedButton` diya gaya hai[cite: 2].
