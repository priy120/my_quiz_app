import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'instructions_screen.dart';
import 'quiz_engine_screen.dart';
import 'solutions_screen.dart';
import 'analysis_screen.dart';
import 'plans_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  final String categoryName;
  final String subCategoryName;

  const TestSeriesScreen({
    super.key,
    this.categoryName = 'SSC',
    this.subCategoryName = 'SSC CGL 2026 - Tier 1',
  });

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSectionFilter = 'Full Tests';
  String _selectedSubFilter = 'All';

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

  void _onTestStartOrResume(String testId, String testTitle, {bool isResume = false, bool isReattempt = false}) {
    if (widget.categoryName.toUpperCase() == 'SSC') {
      _showInterfaceSelectionDialog(testId, testTitle, isResume: isResume, isReattempt: isReattempt);
    } else {
      _navigateToTest(testId, testTitle, isResume: isResume, isReattempt: isReattempt);
    }
  }

  void _showInterfaceSelectionDialog(String testId, String testTitle, {bool isResume = false, bool isReattempt = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Test Interface',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              title: const Text('New Pattern (Eduquity)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                _navigateToTest(testId, testTitle, isResume: isResume, isReattempt: isReattempt);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              title: const Text('Old Pattern (TCS)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                _navigateToTest(testId, testTitle, isResume: isResume, isReattempt: isReattempt);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTest(String testId, String testTitle, {bool isResume = false, bool isReattempt = false}) {
    if (isResume || isReattempt) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizEngineScreen(
            testId: testId,
            testTitle: testTitle,
            isReattempt: isReattempt,
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
    final bool isSSC = widget.categoryName.toUpperCase() == 'SSC';
    final Color primaryColor = isSSC ? const Color(0xFFC62828) : const Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.subCategoryName,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3.5,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Mock Tests'), Tab(text: 'Previous Years')],
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 1. Filter by Category & Subcategory
          var filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docCat = (data['category'] ?? '').toString().trim().toUpperCase();
            final docSubCat = (data['subCategory'] ?? '').toString().trim();
            return docCat == widget.categoryName.trim().toUpperCase() && docSubCat == widget.subCategoryName.trim();
          }).toList();

          // 2. 🔥 Natural Serial Sorting (Test 01, Test 02, Test 03...)
          filteredDocs.sort((a, b) {
            final titleA = (a.data() as Map<String, dynamic>)['title'] ?? '';
            final titleB = (b.data() as Map<String, dynamic>)['title'] ?? '';
            return titleA.toString().compareTo(titleB.toString());
          });

          return Column(
            children: [
              // Custom Filter Segment
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSectionFilter = 'Full Tests'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedSectionFilter == 'Full Tests' ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Full Tests',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _selectedSectionFilter == 'Full Tests' ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSectionFilter = 'Sectional Tests'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedSectionFilter == 'Sectional Tests' ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Sectional Tests',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _selectedSectionFilter == 'Sectional Tests' ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: Row(
                  children: ['All', 'Free', 'Latest Tests'].map((filter) {
                    final isSel = _selectedSubFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (val) => setState(() => _selectedSubFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFilteredTestList(filteredDocs, 'Mocks Tests', primaryColor),
                    _buildFilteredTestList(filteredDocs, 'Previous Years', primaryColor),
                  ],
                ),
              ),

              // Bottom Buy Pass CTA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, -2))
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Unlock Full Test Series', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Access all mock tests & detailed solutions', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PlansScreen()),
                          );
                        },
                        child: Text('BUY PASS', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilteredTestList(List<QueryDocumentSnapshot> docs, String tabType, Color primaryColor) {
    final user = FirebaseAuth.instance.currentUser;
    final filteredList = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      String testTab = (data['tabType'] ?? 'Mocks Tests').toString();
      bool matchTab = testTab.toLowerCase().contains(tabType.toLowerCase().split(' ')[0]);

      String secType = (data['sectionType'] ?? 'Full Tests').toString();
      bool matchSec = secType == _selectedSectionFilter;

      bool isFree = data['isFree'] ?? false;
      bool matchSub = _selectedSubFilter == 'All' || (_selectedSubFilter == 'Free' && isFree) || _selectedSubFilter == 'Latest Tests';

      return matchTab && matchSec && matchSub;
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text("No $tabType available right now.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final doc = filteredList[index];
        final data = doc.data() as Map<String, dynamic>;
        final testId = doc.id;
        final title = data['title'] ?? 'Mock Test ${index + 1}';
        final duration = data['durationMinutes'] ?? 60;
        final marks = data['totalMarks'] ?? (data['totalQuestions'] != null ? data['totalQuestions'] * 2 : 200);
        final totalQ = data['totalQuestions'] ?? 100;
        final isFree = data['isFree'] ?? false;
        final double cutOff = (data['cutoffMarks'] ?? 40.0).toDouble();

        if (user == null) {
          return _buildTestCard(
            testId: testId,
            title: title,
            duration: duration,
            marks: marks,
            totalQ: totalQ,
            isFree: isFree,
            state: 'start',
            primaryColor: primaryColor,
            cutOff: cutOff,
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('paused_tests').doc(testId).snapshots(),
          builder: (context, pausedSnap) {
            final isPaused = pausedSnap.hasData && pausedSnap.data!.exists;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('test_attempts').doc(testId).snapshots(),
              builder: (context, attemptSnap) {
                final isCompleted = attemptSnap.hasData && attemptSnap.data!.exists;
                
                Map<String, dynamic>? attemptData;
                if (isCompleted) {
                  attemptData = attemptSnap.data!.data() as Map<String, dynamic>?;
                }

                String state = 'start';
                if (isCompleted) {
                  state = 'completed';
                } else if (isPaused) {
                  state = 'resume';
                }

                return _buildTestCard(
                  testId: testId,
                  title: title,
                  duration: duration,
                  marks: marks,
                  totalQ: totalQ,
                  isFree: isFree,
                  state: state,
                  primaryColor: primaryColor,
                  attemptData: attemptData,
                  cutOff: cutOff,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTestCard({
    required String testId,
    required String title,
    required int duration,
    required int marks,
    required int totalQ,
    required bool isFree,
    required String state,
    required Color primaryColor,
    required double cutOff,
    Map<String, dynamic>? attemptData,
  }) {
    double userScore = 0.0;
    int attemptCount = 1;
    bool isPassed = false;

    if (attemptData != null) {
      attemptCount = attemptData['attemptCount'] ?? 1;
      var rawScore = attemptData['score'];
      if (rawScore is num) {
        userScore = rawScore.toDouble();
      } else if (rawScore is String && rawScore.contains('/')) {
        userScore = double.tryParse(rawScore.split('/')[0].trim()) ?? 0.0;
      }
      isPassed = userScore >= cutOff;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state == 'completed'
              ? (isPassed ? Colors.green.shade200 : Colors.red.shade200)
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.assignment_outlined, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isFree ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isFree ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Text(
                    isFree ? 'FREE' : 'PAID',
                    style: TextStyle(
                      color: isFree ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Metadata Chips
            Row(
              children: [
                Icon(Icons.help_outline, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text('$totalQ Que', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(width: 12),
                Icon(Icons.military_tech_outlined, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text('$marks Marks', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text('$duration Min', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),

            // 🔥 Score & Cutoff Analysis Summary Badge (For Completed Tests)
            if (state == 'completed') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPassed ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPassed ? Icons.check_circle : Icons.cancel,
                          color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPassed ? 'Cutoff Cleared 🎉' : 'Cutoff Not Cleared ❌',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Score: ${userScore.toStringAsFixed(1)} / $marks  (Attempt $attemptCount)',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons
            if (state == 'resume')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _onTestStartOrResume(testId, title, isResume: true),
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  label: const Text('RESUME TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              )
            else if (state == 'completed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _onTestStartOrResume(testId, title, isReattempt: true),
                      child: Text('Re-Attempt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SolutionsScreen(testId: testId, testTitle: title),
                        ),
                      ),
                      child: const Text('Solution', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnalysisScreen(
                            testId: testId,
                            testTitle: title,
                            score: userScore,
                            totalQuestions: totalQ,
                            correctCount: 0,
                            wrongCount: 0,
                            unattemptedCount: totalQ,
                          ),
                        ),
                      ),
                      child: const Text('Analysis', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (!isFree) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlansScreen()));
                    } else {
                      _onTestStartOrResume(testId, title, isResume: false);
                    }
                  },
                  child: Text(
                    !isFree ? 'Unlock Pass' : 'Start Test',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
