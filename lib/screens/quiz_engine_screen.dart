import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizEngineScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const QuizEngineScreen({
    super.key,
    this.testId = 'default_test',
    this.testTitle = 'CompeteMe Live Mock Test',
  });

  @override
  State<QuizEngineScreen> createState() => _QuizEngineScreenState();
}

class _QuizEngineScreenState extends State<QuizEngineScreen> {
  int currentQuestionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 600;

  List<Map<String, dynamic>> questions = [];
  bool _isLoadingQuestions = true;
  late List<int?> selectedAnswers;

  @override
  void initState() {
    super.initState();
    _fetchQuestionsFromFirestore();
  }

  Future<void> _fetchQuestionsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .collection('questions')
          .orderBy('questionNo', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          questions = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'section': data['section'] ?? 'General',
              'question': data['questionText'] ?? '',
              'imageUrl': data['imageUrl'] ?? '',
              'options': List<String>.from(data['options'] ?? []),
              'correctIndex': data['correctIndex'] ?? 0,
              'solutionText': data['solutionText'] ?? '',
            };
          }).toList();
          selectedAnswers = List<int?>.filled(questions.length, null);
          _isLoadingQuestions = false;
        });
        _startTimer();
      } else {
        setState(() => _isLoadingQuestions = false);
      }
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    int correctCount = 0;
    int wrongCount = 0;
    int unattemptedCount = 0;

    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == null) {
        unattemptedCount++;
      } else if (selectedAnswers[i] == questions[i]['correctIndex']) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    double totalScore = (correctCount * 2) - (wrongCount * 0.5);
    if (totalScore < 0) totalScore = 0;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Save User Attempt History
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('test_attempts')
          .doc(widget.testId)
          .set({
        'testId': widget.testId,
        'testTitle': widget.testTitle,
        'score': '${totalScore.toStringAsFixed(0)} / ${questions.length * 2}',
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'status': 'Completed',
        'attemptedAt': FieldValue.serverTimestamp(),
      });

      // 2. Save Leaderboard Entry
      await FirebaseFirestore.instance
          .collection('leaderboards')
          .doc(widget.testId)
          .collection('ranks')
          .doc(user.uid)
          .set({
        'userUid': user.uid,
        'userName': user.displayName ?? 'Student',
        'score': totalScore,
        'attemptedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Icon(Icons.stars_rounded, size: 48, color: Colors.amber),
              const SizedBox(height: 8),
              Text('Test Submitted! 🎉',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Score: ${totalScore.toStringAsFixed(0)} / ${questions.length * 2}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreMetric('Correct', '$correctCount', Colors.green),
                  _buildScoreMetric('Wrong', '$wrongCount', Colors.red),
                  _buildScoreMetric('Skipped', '$unattemptedCount', Colors.grey),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('BACK TO DASHBOARD',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildScoreMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.testTitle),
          backgroundColor: const Color(0xFF1A237E),
        ),
        body: const Center(
          child: Text("No questions uploaded in this test yet."),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.testTitle,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentQuestion['section'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                Text(
                  'Q ${currentQuestionIndex + 1} / ${questions.length}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentQuestion['question'],
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: (currentQuestion['options'] as List).length,
                itemBuilder: (context, optIndex) {
                  final isSelected =
                      selectedAnswers[currentQuestionIndex] == optIndex;

                  return Card(
                    elevation: isSelected ? 3 : 1,
                    color: isSelected ? Colors.indigo.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1A237E)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(currentQuestion['options'][optIndex]),
                      leading: Radio<int>(
                        value: optIndex,
                        groupValue: selectedAnswers[currentQuestionIndex],
                        activeColor: const Color(0xFF1A237E),
                        onChanged: (val) {
                          setState(() {
                            selectedAnswers[currentQuestionIndex] = val;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          selectedAnswers[currentQuestionIndex] = optIndex;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: () {
                      setState(() => currentQuestionIndex--);
                    },
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox(),
                if (currentQuestionIndex < questions.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                    ),
                    onPressed: () {
                      setState(() => currentQuestionIndex++);
                    },
                    child: const Text('Next Question',
                        style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: _submitTest,
                    child: const Text('Submit Test',
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
