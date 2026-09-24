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

  void _onTestStartOrResume(String testId, String testTitle, {bool isResume = false}) {
    if (widget.categoryName.toUpperCase() == 'SSC') {
      _showInterfaceSelectionDialog(testId, testTitle, isResume: isResume);
    } else {
      _navigateToTest(testId, testTitle, isResume: isResume);
    }
  }

  void _showInterfaceSelectionDialog(String testId, String testTitle, {bool isResume = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Test Interface Selection', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('New Pattern (Eduquity)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                _navigateToTest(testId, testTitle, isResume: isResume);
              },
            ),
            ListTile(
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => QuizEngineScreen(testId: testId, testTitle: testTitle, isReattempt: false)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => InstructionsScreen(testId: testId, testTitle: testTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSSC = widget.categoryName.toUpperCase() == 'SSC';
    final Color headerColor = isSSC ? const Color(0xFFD32F2F) : const Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.subCategoryName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [Tab(text: 'Mocks Tests'), Tab(text: 'Previous Years')],
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['category'] ?? '').toString().toUpperCase() == widget.categoryName.toUpperCase() &&
                   (data['subCategory'] ?? '').toString() == widget.subCategoryName;
          }).toList();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedSectionFilter = 'Full Tests'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedSectionFilter == 'Full Tests' ? headerColor : Colors.transparent, width: 2))),
                          alignment: Alignment.center,
                          child: Text('Full Tests', style: TextStyle(fontWeight: _selectedSectionFilter == 'Full Tests' ? FontWeight.bold : FontWeight.normal, color: _selectedSectionFilter == 'Full Tests' ? headerColor : Colors.grey)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedSectionFilter = 'Sectional Tests'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedSectionFilter == 'Sectional Tests' ? headerColor : Colors.transparent, width: 2))),
                          alignment: Alignment.center,
                          child: Text('Sectional Tests', style: TextStyle(fontWeight: _selectedSectionFilter == 'Sectional Tests' ? FontWeight.bold : FontWeight.normal, color: _selectedSectionFilter == 'Sectional Tests' ? headerColor : Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ['All', 'Free', 'Latest Tests'].map((filter) {
                    final isSel = _selectedSubFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: headerColor,
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
                    _buildFilteredTestList(filteredDocs, 'Mocks Tests'),
                    _buildFilteredTestList(filteredDocs, 'Previous Years'),
                  ],
                ),
              ),
              // Bottom Buy Now Pass Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1A237E),
                child: SafeArea(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlansScreen()),
                      );
                    },
                    child: const Text('Buy Now Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilteredTestList(List<QueryDocumentSnapshot> docs, String tabType) {
    final user = FirebaseAuth.instance.currentUser;
    final filteredList = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      bool matchTab = (data['tabType'] ?? 'Mocks Tests').toString().toLowerCase().contains(tabType.toLowerCase().split(' ')[0]);
      bool matchSec = (data['sectionType'] ?? 'Full Tests').toString() == _selectedSectionFilter;
      bool isFree = data['isFree'] ?? false;
      bool matchSub = _selectedSubFilter == 'All' || (_selectedSubFilter == 'Free' && isFree) || _selectedSubFilter == 'Latest Tests';
      return matchTab && matchSec && matchSub;
    }).toList();

    if (filteredList.isEmpty) return Center(child: Text("No $tabType found.", style: const TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final doc = filteredList[index];
        final data = doc.data() as Map<String, dynamic>;
        final testId = doc.id;
        final title = data['title'] ?? 'Mock Test';
        final duration = data['durationMinutes'] ?? 60;
        final marks = data['totalMarks'] ?? 200;
        final totalQ = data['totalQuestions'] ?? 100;
        final isFree = data['isFree'] ?? false;

        if (user == null) return _buildTestCard(testId, title, duration, marks, totalQ, isFree, 'start');

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('paused_tests').doc(testId).snapshots(),
          builder: (context, pausedSnap) {
            final isPaused = pausedSnap.hasData && pausedSnap.data!.exists;
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('test_attempts').doc(testId).snapshots(),
              builder: (context, attemptSnap) {
                final isCompleted = attemptSnap.hasData && attemptSnap.data!.exists;
                String state = isPaused ? 'resume' : (isCompleted ? 'completed' : 'start');
                return _buildTestCard(testId, title, duration, marks, totalQ, isFree, state);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTestCard(String testId, String title, int duration, int marks, int totalQ, bool isFree, String state) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFFD32F2F), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
                if (!isFree) const Icon(Icons.lock, color: Colors.red, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text('$totalQ Que  |  $marks Marks  |  $duration Min', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            if (state == 'resume')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
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
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizEngineScreen(testId: testId, testTitle: title, isReattempt: true))),
                      child: const Text('Re-Attempt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SolutionsScreen(testId: testId, testTitle: title))),
                      child: const Text('Solution', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade800),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisScreen(testId: testId, testTitle: title, score: 0, totalQuestions: totalQ, correctCount: 0, wrongCount: 0, unattemptedCount: totalQ))),
                      child: const Text('Analysis', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: () => _onTestStartOrResume(testId, title, isResume: false),
                  child: const Text('Start Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
