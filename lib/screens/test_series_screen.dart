import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'instructions_screen.dart';
import 'quiz_engine_screen.dart';
import 'solutions_screen.dart';
import 'analysis_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  final String categoryName;

  const TestSeriesScreen({
    super.key,
    this.categoryName = 'SSC',
  });

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> with SingleTickerProviderStateMixin {
  late String _selectedCategory;
  String? _selectedSubCategory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryName;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTestStartOrResume(String testId, String testTitle, {bool isResume = false}) {
    if (_selectedCategory.toUpperCase() == 'SSC') {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              title: const Text('New Pattern (Eduquity)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                _navigateToTest(testId, testTitle, isResume: isResume);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
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
    final bool isSSC = _selectedCategory.toUpperCase() == 'SSC';
    final Color primaryBarColor = isSSC ? const Color(0xFFB71C1C) : const Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _selectedSubCategory ?? '$_selectedCategory Packages',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          tabs: const [
            Tab(text: 'Mocks Tests'),
            Tab(text: 'Previous Years'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;

          final categoryDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docCat = (data['category'] ?? '').toString().toUpperCase();
            return docCat == _selectedCategory.toUpperCase();
          }).toList();

          final Set<String> dynamicSubCategories = {};
          for (var doc in categoryDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final subCat = data['subCategory'] ?? data['subCategoryTier'];
            if (subCat != null && subCat.toString().isNotEmpty) {
              dynamicSubCategories.add(subCat.toString());
            }
          }

          final List<String> subCatList = dynamicSubCategories.toList();

          if (_selectedSubCategory == null && subCatList.isNotEmpty) {
            _selectedSubCategory = subCatList.first;
          }

          return Column(
            children: [
              if (subCatList.isNotEmpty)
                Container(
                  color: const Color(0xFF1A237E),
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: subCatList.length,
                    itemBuilder: (context, index) {
                      final sub = subCatList[index];
                      final isSelected = sub == _selectedSubCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            sub,
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
                    _buildFilteredList(categoryDocs, 'Mocks Tests'),
                    _buildFilteredList(categoryDocs, 'Previous Years'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilteredList(List<QueryDocumentSnapshot> categoryDocs, String tabType) {
    final user = FirebaseAuth.instance.currentUser;

    final filtered = categoryDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final docTab = data['tabType'] ?? data['testType'] ?? 'Mocks Tests';
      final docSub = data['subCategory'] ?? data['subCategoryTier'];

      bool matchTab = docTab.toString().toLowerCase().contains(tabType.toLowerCase().split(' ')[0]);
      bool matchSub = _selectedSubCategory == null || docSub == _selectedSubCategory;

      return matchTab && matchSub;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text("No $tabType available in $_selectedCategory.", style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final data = doc.data() as Map<String, dynamic>;
        final testId = doc.id;
        final title = data['title'] ?? 'Mock Test';
        final duration = data['durationMinutes'] ?? 60;
        final marks = data['totalMarks'] ?? 200;
        final isFree = data['isFree'] ?? false;

        if (user == null) {
          return _buildTestCard(testId, title, duration, marks, isFree, 'start');
        }

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
                const Icon(Icons.description, color: Color(0xFFB71C1C), size: 20),
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

            if (state == 'resume')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _onTestStartOrResume(testId, title, isResume: true),
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  label: const Text('RESUME TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              )
            else if (state == 'completed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A237E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _onTestStartOrResume(testId, title, isResume: false),
                      child: const Text('Re-Attempt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _onTestStartOrResume(testId, title, isResume: false),
                  child: const Text('Start Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
