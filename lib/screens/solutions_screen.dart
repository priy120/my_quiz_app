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
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final qData = questions[index].data() as Map<String, dynamic>;
                    final String qText = qData['questionText'] ?? '';
                    final List options = qData['options'] ?? [];
                    final int correctIdx = qData['correctIndex'] ?? 0;
                    final String solution = qData['solutionText'] ?? 'Detailed explanation coming soon.';

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Question ${index + 1} of ${questions.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                          const SizedBox(height: 8),
                          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(qText, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)))),
                          const SizedBox(height: 12),
                          ...List.generate(options.length, (optIdx) {
                            final isCorrect = optIdx == correctIdx;
                            return Card(
                              color: isCorrect ? Colors.green.shade50 : Colors.white,
                              shape: RoundedRectangleBorder(side: BorderSide(color: isCorrect ? Colors.green : Colors.grey.shade300)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isCorrect ? Colors.green : Colors.grey.shade200,
                                  child: Icon(isCorrect ? Icons.check : Icons.close, size: 14, color: isCorrect ? Colors.white : Colors.grey),
                                ),
                                title: Text(options[optIdx].toString()),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
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
