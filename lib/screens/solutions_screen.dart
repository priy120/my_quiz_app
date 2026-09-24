import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_engine_screen.dart';

class SolutionsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const SolutionsScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isReattemptMode = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _extractOptions(dynamic rawOptions) {
    if (rawOptions is List) {
      return rawOptions.map((e) => e.toString()).toList();
    } else if (rawOptions is Map) {
      return rawOptions.values.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${widget.testTitle} - Solutions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizEngineScreen(
                    testId: widget.testId,
                    testTitle: widget.testTitle,
                    isReattempt: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh, color: Colors.amber, size: 18),
            label: const Text('Re-Attempt', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mock_tests').doc(widget.testId).collection('questions').orderBy('questionNo').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final questions = snapshot.data!.docs;
          if (questions.isEmpty) return const Center(child: Text('No solutions available.'));

          return Column(
            children: [
              // Re-Attempt Toggle Header Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text('Re-attempt Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Spacer(),
                    Switch(
                      value: _isReattemptMode,
                      activeColor: const Color(0xFF1A237E),
                      onChanged: (val) {
                        setState(() => _isReattemptMode = val);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final qData = questions[index].data() as Map<String, dynamic>;
                    final String qText = qData['questionText'] ?? '';
                    final List<String> options = _extractOptions(qData['options']);
                    final int correctIdx = qData['correctIndex'] ?? 0;
                    final String solution = qData['solutionText'] ?? 'Detailed explanation coming soon.';

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Question ${index + 1} of ${questions.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                              if (!_isReattemptMode)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('CORRECT ANSWER', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(qText, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)))),
                          const SizedBox(height: 12),
                          ...List.generate(options.length, (optIdx) {
                            final isCorrect = optIdx == correctIdx;
                            Color cardColor = Colors.white;
                            BorderSide border = BorderSide(color: Colors.grey.shade300);

                            if (!_isReattemptMode && isCorrect) {
                              cardColor = Colors.green.shade50;
                              border = const BorderSide(color: Colors.green, width: 2);
                            }

                            return Card(
                              color: cardColor,
                              shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: (!_isReattemptMode && isCorrect) ? Colors.green : Colors.grey.shade200,
                                  child: Icon((!_isReattemptMode && isCorrect) ? Icons.check : Icons.circle_outlined, size: 14, color: (!_isReattemptMode && isCorrect) ? Colors.white : Colors.grey),
                                ),
                                title: Text(options[optIdx]),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          if (!_isReattemptMode)
                            Card(
                              color: Colors.amber.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [const Icon(Icons.lightbulb, color: Colors.amber, size: 18), const SizedBox(width: 6), Text('Explanation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.brown))]),
                                    const SizedBox(height: 6),
                                    Text(solution, style: const TextStyle(fontSize: 12, height: 1.4)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentIndex > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.ease) : null,
                      child: const Text('Previous'),
                    ),
                    Text('${_currentIndex + 1} / ${questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: _currentIndex < questions.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.ease) : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
