import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analysis_screen.dart';

enum QuestionStatus { notVisited, notAnswered, answered, markedForReview, markedAndAnswered }

class QuizEngineScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final bool isReattempt;

  const QuizEngineScreen({
    super.key,
    this.testId = 'default_test',
    this.testTitle = 'CompeteMe Live Mock Test',
    this.isReattempt = false,
  });

  @override
  State<QuizEngineScreen> createState() => _QuizEngineScreenState();
}

class _QuizEngineScreenState extends State<QuizEngineScreen> {
  int currentQuestionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 3600;

  List<Map<String, dynamic>> questions = [];
  bool _isLoadingQuestions = true;
  late List<int?> selectedAnswers;
  late List<QuestionStatus> questionStatuses;
  String _currentLang = 'HI';

  @override
  void initState() {
    super.initState();
    _fetchQuestionsAndSavedState();
  }

  Future<void> _fetchQuestionsAndSavedState() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .collection('questions')
          .orderBy('questionNo', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        questions = snapshot.docs.map((doc) => doc.data()).toList();
        selectedAnswers = List<int?>.filled(questions.length, null);
        questionStatuses = List<QuestionStatus>.filled(questions.length, QuestionStatus.notVisited);

        final user = FirebaseAuth.instance.currentUser;

        if (user != null && !widget.isReattempt) {
          final savedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('paused_tests')
              .doc(widget.testId)
              .get();

          if (savedDoc.exists) {
            final data = savedDoc.data()!;
            _secondsRemaining = data['remainingSeconds'] ?? 3600;
            currentQuestionIndex = data['currentIndex'] ?? 0;
            List<dynamic> savedAnswers = data['selectedAnswers'] ?? [];
            for (int i = 0; i < savedAnswers.length && i < selectedAnswers.length; i++) {
              if (savedAnswers[i] != null) {
                selectedAnswers[i] = savedAnswers[i];
                questionStatuses[i] = QuestionStatus.answered;
              }
            }
          }
        }

        if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
          questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
        }

        setState(() => _isLoadingQuestions = false);
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

  String _getParsedText(String rawText) {
    if (!rawText.contains('\n\n')) return rawText;
    final parts = rawText.split('\n\n');
    if (parts.length >= 2) {
      return _currentLang == 'HI' ? parts[1].trim() : parts[0].trim();
    }
    return rawText;
  }

  void _onQuestionChanged(int newIndex) {
    setState(() {
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }
      currentQuestionIndex = newIndex;
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }
    });
  }

  void _selectOption(int optIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = optIndex;
    });
  }

  void _clearResponse() {
    setState(() {
      selectedAnswers[currentQuestionIndex] = null;
      questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
    });
  }

  void _markForReviewAndNext() {
    setState(() {
      questionStatuses[currentQuestionIndex] = selectedAnswers[currentQuestionIndex] != null
          ? QuestionStatus.markedAndAnswered
          : QuestionStatus.markedForReview;
      if (currentQuestionIndex < questions.length - 1) {
        _onQuestionChanged(currentQuestionIndex + 1);
      }
    });
  }

  void _saveAndNext() {
    setState(() {
      questionStatuses[currentQuestionIndex] = selectedAnswers[currentQuestionIndex] != null
          ? QuestionStatus.answered
          : QuestionStatus.notAnswered;
      if (currentQuestionIndex < questions.length - 1) {
        _onQuestionChanged(currentQuestionIndex + 1);
      }
    });
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('test_attempts')
          .doc(widget.testId)
          .set({
        'testId': widget.testId,
        'testTitle': widget.testTitle,
        'score': '${totalScore.toStringAsFixed(1)} / ${questions.length * 2}',
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'selectedAnswers': selectedAnswers,
        'status': 'Completed',
        'attemptedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(
            testId: widget.testId,
            testTitle: widget.testTitle,
            score: totalScore,
            totalQuestions: questions.length,
            correctCount: correctCount,
            wrongCount: wrongCount,
            unattemptedCount: unattemptedCount,
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.testTitle), backgroundColor: const Color(0xFF1A237E)),
        body: const Center(child: Text("No questions uploaded yet.")),
      );
    }

    final currentQ = questions[currentQuestionIndex];
    final String displayQText = _getParsedText(currentQ['questionText'] ?? '');
    final List<String> displayOptions = List.from(currentQ['options'] ?? []).map((o) => _getParsedText(o.toString())).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.testTitle, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          InkWell(
            onTap: () => setState(() => _currentLang = _currentLang == 'HI' ? 'EN' : 'HI'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
              child: Center(child: Text(_currentLang == 'HI' ? 'हिंदी' : 'ENGLISH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
            child: Text(_formatTime(_secondsRemaining), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text('${currentQ['section'] ?? 'General'}', style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: const Color(0xFF1A237E)),
                      Text('No. ${currentQuestionIndex + 1} / ${questions.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Card(
                    child: Padding(padding: const EdgeInsets.all(14.0), child: Text(displayQText, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(displayOptions.length, (optIdx) {
                      final isSelected = selectedAnswers[currentQuestionIndex] == optIdx;
                      return Card(
                        color: isSelected ? Colors.indigo.shade50 : Colors.white,
                        child: ListTile(
                          dense: true,
                          title: Text(displayOptions[optIdx]),
                          leading: Radio<int>(
                            value: optIdx,
                            groupValue: selectedAnswers[currentQuestionIndex],
                            onChanged: (val) => _selectOption(optIdx),
                          ),
                          onTap: () => _selectOption(optIdx),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          // Fixed Bottom Toolbar with Save & Next
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  OutlinedButton(onPressed: () => _onQuestionChanged(currentQuestionIndex - 1), child: const Text('Prev'))
                else
                  const SizedBox(width: 40),
                OutlinedButton(onPressed: _clearResponse, child: const Text('Clear', style: TextStyle(color: Colors.orange))),
                OutlinedButton(onPressed: _markForReviewAndNext, child: const Text('Review', style: TextStyle(color: Colors.purple))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  onPressed: _saveAndNext,
                  child: const Text('Save & Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
