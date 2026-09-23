import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'instructions_screen.dart';
import 'quiz_engine_screen.dart';
import 'solutions_screen.dart';
import 'analysis_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'SSC';
  String _selectedSubCategory = 'SSC CGL 2026 - Tier 1';
  late TabController _tabController;

  final List<String> _subCategories = [
    'SSC CGL 2026 - Tier 1',
    'SSC CPO 2026 - Tier 1',
    'SSC CPO 2025 - Tier 2',
    'SSC CHSL 2026 - Tier 1',
    'SSC CGL 2026 - Tier 2',
    'SSC GD Constable 2026',
    'SSC MTS 2026',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInterfaceSelectionDialog(String testId, String testTitle, {bool isResume = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Test Interface Selection',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Which test interface you want to use?', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              title: const Text('New Pattern (Eduquity)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                _navigateToTest(testId, testTitle, isResume: isResume);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              title: const Text('Old Pattern (TCS)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                _navigateToTest(testId, testTitle, isResume: isResume);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTest(String testId, String testTitle, {bool isResume = false}) {
    if (isResume) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizEngineScreen(
            testId: testId,
            testTitle: testTitle,
            isReattempt: false,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InstructionsScreen(
            testId: testId,
            testTitle: testTitle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C), // Matching Red Theme from Video
        elevation: 0,
        title: Text(
          _selectedSubCategory,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Mocks Tests (82)'),
            Tab(text: 'Previous Years (1037)'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // Horizontal Sub-Exam Chips
          Container(
            color: const Color(0xFF1A237E),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _subCategories.length,
              itemBuilder: (context, index) {
                final sub = _subCategories[index];
                final isSelected = sub == _selectedSubCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      sub.replaceAll(' 2026', '').replaceAll(' 2025', ''),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1A237E) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white24,
                    onSelected: (val) {
                      setState(() => _selectedSubCategory = sub);
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTestListSection('Full Mock'),
                _buildTestListSection('PYQ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestListSection(String testType) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mock_tests')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No tests available in this section."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final testId = doc.id;
            final title = data['title'] ?? 'Mock Test';
            final duration = data['durationMinutes'] ?? 60;
            final marks = data['totalMarks'] ?? 200;
            final isFree = data['isFree'] ?? false;

            if (user == null) {
              return _buildTestCard(testId, title, duration, marks, isFree, 'start');
            }

            // Real-time State Check (Paused vs Attempted vs Fresh)
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('paused_tests')
                  .doc(testId)
                  .snapshots(),
              builder: (context, pausedSnap) {
                final isPaused = pausedSnap.hasData && pausedSnap.data!.exists;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('test_attempts')
                      .doc(testId)
                      .snapshots(),
                  builder: (context, attemptSnap) {
                    final isCompleted = attemptSnap.hasData && attemptSnap.data!.exists;

                    String state = 'start';
                    if (isPaused) {
                      state = 'resume';
                    } else if (isCompleted) {
                      state = 'completed';
                    }

                    return _buildTestCard(testId, title, duration, marks, isFree, state);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTestCard(String testId, String title, int duration, int marks, bool isFree, String state) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFFB71C1C), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                if (!isFree) const Icon(Icons.lock, color: Colors.amber, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$duration Mins', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 12),
                Text('$marks Marks', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Divider(height: 20),
            
            // Dynamic Button Rendering Based on State
            if (state == 'resume')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  onPressed: () => _showInterfaceSelectionDialog(testId, title, isResume: true),
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  label: const Text('RESUME TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            else if (state == 'completed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1A237E))),
                      onPressed: () => _showInterfaceSelectionDialog(testId, title, isResume: false),
                      child: const Text('Re-Attempt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SolutionsScreen(testId: testId, testTitle: title),
                          ),
                        );
                      },
                      child: const Text('Solution', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade800),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalysisScreen(
                              testId: testId,
                              testTitle: title,
                              score: 0,
                              totalQuestions: 100,
                              correctCount: 0,
                              wrongCount: 0,
                              unattemptedCount: 100,
                            ),
                          ),
                        );
                      },
                      child: const Text('Analysis', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  onPressed: () => _showInterfaceSelectionDialog(testId, title, isResume: false),
                  child: const Text('Start Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
