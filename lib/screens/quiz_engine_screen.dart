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
  late PageController _pageController;
  int currentQuestionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 3600; // Dynamic default

  List<Map<String, dynamic>> questions = [];
  bool _isLoadingQuestions = true;
  late List<int?> selectedAnswers;
  late List<QuestionStatus> questionStatuses;
  String _currentLang = 'HI';

  // Section Tracking
  final List<String> _sections = ['Quantitative Aptitude', 'Logical Reasoning', 'English Language', 'General Awareness'];
  int _currentSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchQuestionsAndSavedState();
  }

  Future<void> _fetchQuestionsAndSavedState() async {
    try {
      // 1. Fetch Test Details (Dynamic Time in Minutes from Admin Panel)
      final testDoc = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .get();

      if (testDoc.exists) {
        final testData = testDoc.data();
        int adminDurationMinutes = testData?['durationMinutes'] ?? 60;
        _secondsRemaining = adminDurationMinutes * 60; // Admin time in seconds
      }

      // 2. Fetch Questions
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
            _secondsRemaining = data['remainingSeconds'] ?? _secondsRemaining;
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

        _pageController = PageController(initialPage: currentQuestionIndex);
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

  List<String> _extractOptions(dynamic rawOptions) {
    if (rawOptions is List) {
      return rawOptions.map((e) => _getParsedText(e.toString())).toList();
    } else if (rawOptions is Map) {
      return rawOptions.values.map((e) => _getParsedText(e.toString())).toList();
    }
    return ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  }

  void _onQuestionPageChanged(int index) {
    setState(() {
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }
      currentQuestionIndex = index;
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }
    });
  }

  void _navigateToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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
        _navigateToQuestion(currentQuestionIndex + 1);
      }
    });
  }

  void _saveAndNext() {
    setState(() {
      questionStatuses[currentQuestionIndex] = selectedAnswers[currentQuestionIndex] != null
          ? QuestionStatus.answered
          : QuestionStatus.notAnswered;
      if (currentQuestionIndex < questions.length - 1) {
        _navigateToQuestion(currentQuestionIndex + 1);
      }
    });
  }

  void _showSectionToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You can't switch to the next tab without submitting this section"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _openQuestionPaletteSheet() {
    int answeredCount = questionStatuses.where((s) => s == QuestionStatus.answered).length;
    int markedCount = questionStatuses.where((s) => s == QuestionStatus.markedForReview).length;
    int notVisitedCount = questionStatuses.where((s) => s == QuestionStatus.notVisited).length;
    int markedAndAnsweredCount = questionStatuses.where((s) => s == QuestionStatus.markedAndAnswered).length;
    int notAnsweredCount = questionStatuses.where((s) => s == QuestionStatus.notAnswered).length;

    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildLegendBadge(Colors.green, '$answeredCount Answered'),
                  _buildLegendBadge(Colors.purple, '$markedCount Marked'),
                  _buildLegendBadge(Colors.grey.shade300, '$notVisitedCount Not Visited', textColor: Colors.black),
                  _buildLegendBadge(Colors.blue, '$markedAndAnsweredCount Marked & Answered'),
                  _buildLegendBadge(Colors.red, '$notAnsweredCount Not Answered'),
                ],
              ),
              const SizedBox(height: 10),
              Text('SECTION : ${_sections[_currentSectionIndex]}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                        _navigateToQuestion(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Question Paper', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Instructions', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmSubmitDialog(isSectionSubmit: true);
                  },
                  child: const Text('Submit This Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmSubmitDialog(isSectionSubmit: false);
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

  void _confirmSubmitDialog({bool isSectionSubmit = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSectionSubmit ? 'CONFIRM SECTION SUBMIT' : 'CONFIRM TEST SUBMIT'),
        content: Text(isSectionSubmit ? 'Are you sure you want to submit this section?' : 'Are you sure you want to submit the entire test now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () {
              Navigator.pop(context);
              if (isSectionSubmit) {
                if (_currentSectionIndex < _sections.length - 1) {
                  setState(() => _currentSectionIndex++);
                }
              } else {
                _submitTest();
              }
            },
            child: const Text('Yes, Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
    _pageController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.testTitle, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.g_translate, color: Colors.white, size: 20),
            onSelected: (val) => setState(() => _currentLang = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'EN', child: Text('English')),
              const PopupMenuItem(value: 'HI', child: Text('हिंदी')),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
            child: Text(_formatTime(_secondsRemaining), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10)),
          ),
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: () {}),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.green.shade700,
        onPressed: _openQuestionPaletteSheet,
        child: const Icon(Icons.grid_view, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A237E),
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final isSel = _currentSectionIndex == index;
                return GestureDetector(
                  onTap: () {
                    if (index != _currentSectionIndex) {
                      _showSectionToast();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.indigo.shade900 : Colors.transparent,
                      border: Border(bottom: BorderSide(color: isSel ? Colors.amber : Colors.transparent, width: 3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _sections[index],
                      style: TextStyle(
                        color: isSel ? Colors.amber : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onQuestionPageChanged,
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final qData = questions[index];
                final String displayQText = _getParsedText(qData['questionText'] ?? '');
                final List<String> displayOptions = _extractOptions(qData['options']);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('No. ${index + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.bookmark_border, size: 20), onPressed: () {}),
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            ],
                          ),
                        ],
                      ),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Text(displayQText, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(displayOptions.length, (optIdx) {
                          final isSelected = selectedAnswers[index] == optIdx;
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
                                groupValue: selectedAnswers[index],
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
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: currentQuestionIndex > 0 ? () => _navigateToQuestion(currentQuestionIndex - 1) : null,
                    child: const Text('Previous Question', style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purple), padding: EdgeInsets.zero),
                    onPressed: _markForReviewAndNext,
                    child: const Text('Mark & Save For Review', style: TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: EdgeInsets.zero),
                    onPressed: _clearResponse,
                    child: const Text('Clear Response', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), padding: EdgeInsets.zero),
                    onPressed: _saveAndNext,
                    child: const Text('Save & Next', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
