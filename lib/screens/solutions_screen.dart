import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  List<Map<String, dynamic>> _questions = [];
  List<dynamic> _userSelectedAnswers = [];
  bool _isLoading = true;
  String _activeFilter = 'All'; // All, Incorrect, Unattempted

  @override
  void initState() {
    super.initState();
    _fetchQuestionsAndUserAttempt();
  }

  Future<void> _fetchQuestionsAndUserAttempt() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Fetch Questions
      final qSnapshot = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .collection('questions')
          .orderBy('questionNo', descending: false)
          .get();

      if (qSnapshot.docs.isNotEmpty) {
        _questions = qSnapshot.docs.map((doc) => doc.data()).toList();
      }

      // 2. Fetch User Attempt Response from Firebase
      if (user != null) {
        final attemptDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('test_attempts')
            .doc(widget.testId)
            .get();

        if (attemptDoc.exists) {
          final data = attemptDoc.data()!;
          _userSelectedAnswers = data['selectedAnswers'] ?? [];
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter Questions List
    final filteredQuestions = _questions.where((q) {
      int index = _questions.indexOf(q);
      int? userAns = index < _userSelectedAnswers.length ? _userSelectedAnswers[index] : null;
      int correctAns = q['correctIndex'] ?? 0;

      if (_activeFilter == 'Incorrect') {
        return userAns != null && userAns != correctAns;
      } else if (_activeFilter == 'Unattempted') {
        return userAns == null;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Solutions: ${widget.testTitle}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            ),
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
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('RE-ATTEMPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text("No solutions data found."))
              : Column(
                  children: [
                    // Filter Chips Bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: ['All', 'Incorrect', 'Unattempted'].map((filter) {
                          final isSelected = _activeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade100,
                              onSelected: (val) {
                                setState(() => _activeFilter = filter);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: filteredQuestions.isEmpty
                          ? Center(child: Text("No $filter questions found."))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredQuestions.length,
                              itemBuilder: (context, index) {
                                final q = filteredQuestions[index];
                                final originalIndex = _questions.indexOf(q);
                                final questionText = q['questionText'] ?? '';
                                final options = List<String>.from(q['options'] ?? []);
                                final correctIndex = q['correctIndex'] ?? 0;
                                final solutionText = q['solutionText'] ?? 'No detailed explanation available.';

                                final int? userAns = originalIndex < _userSelectedAnswers.length ? _userSelectedAnswers[originalIndex] : null;
                                final bool isAttempted = userAns != null;
                                final bool isUserCorrect = userAns == correctIndex;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Q. ${originalIndex + 1} (${q['section'] ?? 'General'})',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                              ),
                                            ),
                                            // User Attempt Badge
                                            if (!isAttempted)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('UNATTEMPTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              )
                                            else if (isUserCorrect)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('CORRECT (+2)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('INCORRECT (-0.5)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(questionText, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 12),
                                        Column(
                                          children: List.generate(options.length, (optIdx) {
                                            final isCorrectOpt = optIdx == correctIndex;
                                            final isUserSelectedOpt = optIdx == userAns;

                                            Color cardBg = Colors.white;
                                            Color borderColor = Colors.grey.shade300;
                                            IconData icon = Icons.radio_button_unchecked;
                                            Color iconColor = Colors.grey;

                                            if (isCorrectOpt) {
                                              cardBg = Colors.green.shade50;
                                              borderColor = Colors.green;
                                              icon = Icons.check_circle;
                                              iconColor = Colors.green;
                                            } else if (isUserSelectedOpt && !isUserCorrect) {
                                              cardBg = Colors.red.shade50;
                                              borderColor = Colors.red;
                                              icon = Icons.cancel;
                                              iconColor = Colors.red;
                                            }

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: cardBg,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: borderColor, width: isCorrectOpt || isUserSelectedOpt ? 1.5 : 1),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(icon, color: iconColor, size: 20),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      options[optIdx],
                                                      style: TextStyle(
                                                        color: isCorrectOpt ? Colors.green.shade900 : (isUserSelectedOpt ? Colors.red.shade900 : Colors.black87),
                                                        fontWeight: isCorrectOpt || isUserSelectedOpt ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isUserSelectedOpt)
                                                    const Text(' (Your Answer)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                                ],
                                              ),
                                            );
                                          }),
                                        ),
                                        const Divider(height: 24),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 20),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Explanation / Solution:',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(solutionText, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
