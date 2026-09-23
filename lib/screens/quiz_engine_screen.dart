import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analysis_screen.dart';

enum QuestionStatus { notVisited, notAnswered, answered, markedForReview }

class QuizEngineScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final bool isReattempt;

  const QuizEngineScreen({
    super.key,
    required this.testId,
    required this.testTitle,
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

        // Fetch Saved Paused State if not re-attemping
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

  // PAUSE TEST & SAVE STATE TO FIRESTORE
  Future<void> _pauseAndExitTest() async {
    _timer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('paused_tests')
          .doc(widget.testId)
          .set({
        'testId': widget.testId,
        'remainingSeconds': _secondsRemaining,
        'currentIndex': currentQuestionIndex,
        'selectedAnswers': selectedAnswers,
        'pausedAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) Navigator.pop(context);
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PAUSE TEST'),
        content: const Text('Are you sure you want to pause & close this test? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () {
              Navigator.pop(context);
              _pauseAndExitTest();
            },
            child: const Text('Yes, Pause', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      questionStatuses[currentQuestionIndex] = QuestionStatus.answered;
    });
  }

  void _toggleMarkForReview() {
    setState(() {
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.markedForReview) {
        questionStatuses[currentQuestionIndex] = selectedAnswers[currentQuestionIndex] != null
            ? QuestionStatus.answered
            : QuestionStatus.notAnswered;
      } else {
        questionStatuses[currentQuestionIndex] = QuestionStatus.markedForReview;
      }
    });
  }

  void _openQuestionPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Question Palette', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildLegendItem(Colors.green, 'Answered'),
                  _buildLegendItem(Colors.red, 'Not Answered'),
                  _buildLegendItem(Colors.blue, 'Review'),
                  _buildLegendItem(Colors.grey.shade300, 'Not Visited', textColor: Colors.black),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final status = questionStatuses[index];
                    Color bgColor;
                    Color textColor = Colors.white;

                    switch (status) {
                      case QuestionStatus.answered:
                        bgColor = Colors.green;
                        break;
                      case QuestionStatus.notAnswered:
                        bgColor = Colors.red;
                        break;
                      case QuestionStatus.markedForReview:
                        bgColor = Colors.blue;
                        break;
                      case QuestionStatus.notVisited:
                      default:
                        bgColor = Colors.grey.shade300;
                        textColor = Colors.black;
                        break;
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _onQuestionChanged(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, {Color textColor = Colors.white}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
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
      // 1. Save Full Attempt Response in Firestore
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

      // 2. Clear Paused Saved State
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('paused_tests')
          .doc(widget.testId)
          .delete();

      // 3. Save Leaderboard Entry
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
      Navigator.pushReplacement(
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
        body: const Center(child: Text("No questions uploaded in this test yet.")),
      );
    }

    final currentQ = questions[currentQuestionIndex];
    final String qText = currentQ['questionText'] ?? currentQ['question'] ?? '';
    final List options = List.from(currentQ['options'] ?? []);

    return WillPopScope(
      onWillPop: () async {
        _showPauseDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.testTitle,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pause_circle_outline, color: Colors.amber),
              onPressed: _showPauseDialog,
            ),
            TextButton(
              onPressed: () => setState(() => _currentLang = _currentLang == 'HI' ? 'EN' : 'HI'),
              child: Text(
                _currentLang == 'HI' ? 'हिंदी' : 'ENGLISH',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
              child: Text(_formatTime(_secondsRemaining), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
            ),
            IconButton(
              icon: const Icon(Icons.grid_view, color: Colors.white),
              onPressed: _openQuestionPalette,
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
                  Chip(
                    label: Text(currentQ['section'] ?? 'General', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.blue.shade100,
                  ),
                  Text('Q ${currentQuestionIndex + 1} / ${questions.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(qText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, optIdx) {
                    final isSelected = selectedAnswers[currentQuestionIndex] == optIdx;
                    return Card(
                      elevation: isSelected ? 3 : 1,
                      color: isSelected ? Colors.indigo.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(options[optIdx]),
                        leading: Radio<int>(
                          value: optIdx,
                          groupValue: selectedAnswers[currentQuestionIndex],
                          activeColor: const Color(0xFF1A237E),
                          onChanged: (val) => _selectOption(optIdx),
                        ),
                        onTap: () => _selectOption(optIdx),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _toggleMarkForReview,
                    icon: const Icon(Icons.bookmark_border, size: 16),
                    label: const Text('Review', style: TextStyle(fontSize: 11)),
                  ),
                  Row(
                    children: [
                      if (currentQuestionIndex > 0)
                        TextButton(
                          onPressed: () => _onQuestionChanged(currentQuestionIndex - 1),
                          child: const Text('Prev'),
                        ),
                      const SizedBox(width: 8),
                      if (currentQuestionIndex < questions.length - 1)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                          onPressed: () => _onQuestionChanged(currentQuestionIndex + 1),
                          child: const Text('Next', style: TextStyle(color: Colors.white)),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                          onPressed: _submitTest,
                          child: const Text('Submit', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
