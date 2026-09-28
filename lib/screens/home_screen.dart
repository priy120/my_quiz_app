import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart'; // Unity Ads Import
import '../utils/app_updater.dart';
import 'exam_categories_screen.dart';
import 'pdfs_screen.dart';
import 'profile_screen.dart';
import 'my_tests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // App khulte hi background me auto-update check karega
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdater.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1Here is a review of your `home_screen.dart` file[cite: 1] with identified issues, recommended cleanups, and a corrected complete file.

---

### Key Issues & Fixes Needed

1. **`BottomNavigationBar` Navigation Stack Overflow**
   - **Issue:** Using `Navigator.push` inside `BottomNavigationBar.onTap`[cite: 1] pushes new routes on top of the stack without updating the active screen index cleanly or popping previous screens. This leads to a stacked back-button experience.
   - **Fix:** If using bottom navigation tabs on a single root screen, switch screens via state (e.g., an `IndexedStack` or returning a `Widget` body depending on `_currentIndex`), or reset navigation state properly.

2. **Duplicate Routes in Options & Bottom Bar**
   - **Issue:** "Free PDFs" and "Toppers Notes" both route to `PdfScreen()`[cite: 1]. Additionally, tapping items on the bottom bar pushes pages that duplicate grid card actions[cite: 1].
   - **Fix:** Pass custom arguments (e.g., tab category name) to `PdfScreen` if it's meant to show distinct content.

3. **Deprecated Flutter API Usage**
   - **Issue:** `withOpacity()` is being used directly on `Color` instances (e.g., `color.withOpacity(0.15)`)[cite: 1]. In newer Flutter versions, `color.withValues(alpha: 0.15)` is preferred to avoid deprecation warnings.

4. **Odd Grid Layout Spacing**
   - **Issue:** You have an odd number of items (5 items)[cite: 1] in a 2-column grid[cite: 1], leaving an uneven trailing spot on the bottom right. 
   - **Fix:** Add a 6th category (e.g., "Previous Papers") to balance the `GridView` visual flow.

---

### Optimized Code

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_updater.dart';
import 'exam_categories_screen.dart';
import 'pdfs_screen.dart';
import 'profile_screen.dart';
import 'my_tests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdater.checkForUpdate(context);
    });
  }

  // Screens corresponding to BottomNavigationBar items
  late final List<Widget> _screens = [
    _buildDashboardBody(),
    const MyTestsScreen(),
    const PdfScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CompeteMe Portal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              'Student Learning Dashboard',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'My Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'PDFs',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Main Dashboard View
  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Selection Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Selection 2026 🎯',
                        style: GoogleFonts.poppins(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Attempt Standard Full Length Mock Tests & Instant Analysis',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: Colors.amber, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Explore Categories',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),

          // Grid of Options
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildOptionCard(
                title: 'Test Series',
                subtitle: 'Paid & Free Mocks',
                icon: Icons.assignment_outlined,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExamCategoriesScreen(),
                    ),
                  );
                },
              ),
              _buildOptionCard(
                title: 'Daily Quiz',
                subtitle: 'Timer Based Test',
                icon: Icons.timer_outlined,
                color: Colors.green,
                onTap: () {},
              ),
              _buildOptionCard(
                title: 'Free PDFs',
                subtitle: 'Class Notes & Sheets',
                icon: Icons.picture_as_pdf_outlined,
                color: Colors.purple,
                onTap: () {
                  setState(() => _currentIndex = 2); // Switches to PDFs tab
                },
              ),
              _buildOptionCard(
                title: 'Current Affairs',
                subtitle: 'Daily & Monthly',
                icon: Icons.newspaper_outlined,
                color: Colors.blue,
                onTap: () {},
              ),
              _buildOptionCard(
                title: 'Toppers Notes',
                subtitle: 'Handwritten Notes',
                icon: Icons.menu_book_outlined,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PdfScreen(),
                    ),
                  );
                },
              ),
              _buildOptionCard(
                title: 'Previous Papers',
                subtitle: 'PYQ Mocks & PDFs',
                icon: Icons.history_edu_outlined,
                color: Colors.redAccent,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
