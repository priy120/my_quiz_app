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

  String _currentLang = 'HI'; // Default Hindi, toggles to 'EN'

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

  // Parse bilingual text based on current language selection
  String _getParsedText(String rawText) {
    if (!rawText.contains('\n\n')) return rawText;
    final parts = rawText.split('\n\n');
    if (parts.length >= 2) {
      return _currentLang == 'HI' ? parts[1].trim() : parts[0].trim();
    }
    return rawText;
  }

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
        title: const Text('PAUSE TEST', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to pause & close this test? Your progress will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
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
      if (selectedAnswers[currentQuestionIndex] != null) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.markedAndAnswered;
      } else {
        questionStatuses[currentQuestionIndex] = QuestionStatus.markedForReview;
      }
      if (currentQuestionIndex < questions.length - 1) {
        _onQuestionChanged(currentQuestionIndex + 1);
      }
    });
  }

  void _saveAndNext() {
    setState(() {
      if (selectedAnswers[currentQuestionIndex] != null) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.answered;
      } else {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }
      if (currentQuestionIndex < questions.length - 1) {
        _onQuestionChanged(currentQuestionIndex + 1);
      }
    });
  }

  void _openQuestionPalette() {
    final user = FirebaseAuth.instance.currentUser;
    int answeredCount = questionStatuses.where((s) => s == QuestionStatus.answered).length;
    int markedCount = questionStatuses.where((s) => s == QuestionStatus.markedForReview).length;
    int notVisitedCount = questionStatuses.where((s) => s == QuestionStatus.notVisited).length;
    int markedAndAnsweredCount = questionStatuses.where((s) => s == QuestionStatus.markedAndAnswered).length;
    int notAnsweredCount = questionStatuses.where((s) => s == QuestionStatus.notAnswered).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 10),
                  Text(user?.displayName ?? 'Priyanshu', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _buildLegendBadge(Colors.green, '$answeredCount Answered'),
                  _buildLegendBadge(Colors.purple, '$markedCount Marked'),
                  _buildLegendBadge(Colors.grey.shade300, '$notVisitedCount Not Visited', textColor: Colors.black),
                  _buildLegendBadge(Colors.blue, '$markedAndAnsweredCount Marked & Answered'),
                  _buildLegendBadge(Colors.red, '$notAnsweredCount Not Answered'),
                ],
              ),
              const Divider(height: 20),
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
                      case QuestionStatus.markedForReview:
                        bgColor = Colors.purple;
                        break;
                      case QuestionStatus.markedAndAnswered:
                        bgColor = Colors.blue;
                        break;
                      case QuestionStatus.notAnswered:
                        bgColor = Colors.red;
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  onPressed: () {
                    Navigator.pop(context);
                    _submitTest();
                  },
                  child: const Text('Submit Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendBadge(Color color, String label, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('paused_tests')
          .doc(widget.testId)
          .delete();
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
        body: const Center(child: Text("No questions uploaded in this test yet.")),
      );
    }

    final currentQ = questions[currentQuestionIndex];
    final String rawQText = currentQ['questionText'] ?? currentQ['question'] ?? '';
    final String displayQText = _getParsedText(rawQText);

    final List rawOptions = List.from(currentQ['options'] ?? []);
    final List<String> displayOptions = rawOptions.map((opt) => _getParsedText(opt.toString())).toList();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _showPauseDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.testTitle,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.pause_circle_outline, color: Colors.amber), onPressed: _showPauseDialog),
            
            // Dynamic Language Switcher Toggle
            InkWell(
              onTap: () {
                setState(() {
                  _currentLang = _currentLang == 'HI' ? 'EN' : 'HI';
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _currentLang == 'HI' ? 'हिंदी' : 'ENGLISH',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
              child: Text(_formatTime(_secondsRemaining), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
            ),
            IconButton(icon: const Icon(Icons.grid_view, color: Colors.white), onPressed: _openQuestionPalette),
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
                        Chip(
                          label: Text('${currentQ['section'] ?? 'General'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          backgroundColor: const Color(0xFF1A237E),
                        ),
                        Text('No. ${currentQuestionIndex + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(displayQText, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: List.generate(displayOptions.length, (optIdx) {
                        final isSelected = selectedAnswers[currentQuestionIndex] == optIdx;
                        return Card(
                          elevation: isSelected ? 2 : 1,
                          color: isSelected ? Colors.indigo.shade50 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            title: Text(displayOptions[optIdx], style: const TextStyle(fontSize: 13)),
                            leading: Radio<int>(
                              value: optIdx,
                              groupValue: selectedAnswers[currentQuestionIndex],
                              activeColor: const Color(0xFF1A237E),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Row(
                children: [
                  if (currentQuestionIndex > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                      onPressed: () => _onQuestionChanged(currentQuestionIndex - 1),
                      child: const Text('Previous Question', style: TextStyle(fontSize: 10)),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _markForReviewAndNext,
                    child: const Text('Mark & Save For Review', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _clearResponse,
                    child: const Text('Clear Response', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: _saveAndNext,
                    child: const Text('Save & Next', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
