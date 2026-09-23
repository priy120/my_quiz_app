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
  int _currentIndex = 0;
  bool _isReattemptMode = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestionsAndUserAttempt();
  }

  Future<void> _fetchQuestionsAndUserAttempt() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      final qSnapshot = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .collection('questions')
          .orderBy('questionNo', descending: false)
          .get();

      if (qSnapshot.docs.isNotEmpty) {
        _questions = qSnapshot.docs.map((doc) => doc.data()).toList();
      }

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

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Test Feedback', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Did you like the Solutions?', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.amber, size: 30)),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Comment (Optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Skip ✕', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.testTitle), backgroundColor: const Color(0xFF1A237E)),
        body: const Center(child: Text("No solutions available for this test.")),
      );
    }

    final q = _questions[_currentIndex];
    final questionText = q['questionText'] ?? '';
    final options = List<String>.from(q['options'] ?? []);
    final correctIndex = q['correctIndex'] ?? 0;
    final solutionText = q['solutionText'] ?? 'Detailed explanation coming soon.';

    final int? userAns = _currentIndex < _userSelectedAnswers.length ? _userSelectedAnswers[_currentIndex] : null;
    final bool isAttempted = userAns != null;
    final bool isUserCorrect = userAns == correctIndex;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Solutions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
            child: const Text('Attempt 1 ▾', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // Section Bar
          Container(
            color: const Color(0xFF1A237E),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'PART-B (${q['section'] ?? 'General Intelligence'})',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & % Correct Badge Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Q. ${_currentIndex + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          if (!isAttempted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                              child: const Text('SKIPPED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                            )
                          else if (isUserCorrect)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                              child: const Text('CORRECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                              child: const Text('INCORRECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green.shade300), borderRadius: BorderRadius.circular(12)),
                        child: const Text('88.19% answered correctly', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Time 00:08   Avg. Time 01:05', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // Question Text
                  Text(questionText, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 14),

                  // Options List with Video Style Badges
                  Column(
                    children: List.generate(options.length, (optIdx) {
                      final isCorrectOpt = optIdx == correctIndex;
                      final isUserSelectedOpt = optIdx == userAns;

                      Color cardBg = Colors.white;
                      Color borderColor = Colors.grey.shade300;
                      Widget leadingWidget = CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey.shade200,
                        child: Text('${optIdx + 1}', style: const TextStyle(fontSize: 10, color: Colors.black)),
                      );

                      if (!_isReattemptMode) {
                        if (isCorrectOpt) {
                          cardBg = Colors.green.shade50;
                          borderColor = Colors.green;
                          leadingWidget = const Icon(Icons.check_circle, color: Colors.green, size: 20);
                        } else if (isUserSelectedOpt && !isUserCorrect) {
                          cardBg = Colors.red.shade50;
                          borderColor = Colors.red;
                          leadingWidget = const Icon(Icons.cancel, color: Colors.red, size: 20);
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: isCorrectOpt || isUserSelectedOpt ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            leadingWidget,
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                options[optIdx],
                                style: TextStyle(
                                  color: !_isReattemptMode && isCorrectOpt ? Colors.green.shade900 : Colors.black87,
                                  fontWeight: !_isReattemptMode && (isCorrectOpt || isUserSelectedOpt) ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  const Divider(height: 24),

                  // Solution Explanation Card
                  if (!_isReattemptMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Explanation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF1A237E))),
                          const SizedBox(height: 6),
                          Text(solutionText, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Bar (Previous, Re-attempt Toggle, Next)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                  child: const Text('Previous', style: TextStyle(fontSize: 11)),
                ),
                Row(
                  children: [
                    Switch(
                      value: _isReattemptMode,
                      activeColor: const Color(0xFF1A237E),
                      onChanged: (val) => setState(() => _isReattemptMode = val),
                    ),
                    const Text('Re-attempt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  onPressed: () {
                    if (_currentIndex < _questions.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      _showFeedbackDialog();
                    }
                  },
                  child: Text(_currentIndex == _questions.length - 1 ? 'Finish' : 'Next', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
