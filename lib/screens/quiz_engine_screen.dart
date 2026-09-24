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
  List<int?> selectedAnswers = [];
  List<QuestionStatus> questionStatuses = [];
  String _currentLang = 'HI';
  bool _isPaletteExpanded = false; // Question Palette toggle control

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
      // 1. Fetch Test Details
      final testDoc = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .get();

      if (testDoc.exists) {
        final testData = testDoc.data();
        int adminDurationMinutes = testData?['durationMinutes'] ?? 60;
        _secondsRemaining = adminDurationMinutes * 60;
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
        if (mounted) setState(() => _isLoadingQuestions = false);
        _startTimer();
      } else {
        if (mounted) setState(() => _isLoadingQuestions = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    return '${minutes.toStringAndPadLeft(2, '0')}:${seconds.toStringAndPadLeft(2, '0')}';
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

  // --- PAUSE & SAVE TEST LOGIC ---
  Future<bool> _onWillPop() async {
    final shouldPause = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Test?'),
        content: const Text('Do you want to pause your test and exit? Your progress will be saved so you can resume later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Resume Test'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              await _pauseAndSaveTest();
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Pause & Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldPause ?? false;
  }

  Future<void> _pauseAndSaveTest() async {
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
        'testTitle': widget.testTitle,
        'remainingSeconds': _secondsRemaining,
        'currentIndex': currentQuestionIndex,
        'selectedAnswers': selectedAnswers,
        'pausedAt': FieldValue.serverTimestamp(),
      });
    }
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
      // Clear paused test state upon completion
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('paused_tests')
          .doc(widget.testId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('test_attempts')
          .doc(widget.testId)
          .set({
        'testId': widget.testId,
        'testTitle': widget.testTitle,
        'score': totalScore,
        'maxScore': questions.length * 2,
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

  // Question Palette Legend Helper
  Widget _buildLegendBadge(Color color, String label, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
    );
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
            IconButton(
              icon: const Icon(Icons.pause_circle_outline, color: Colors.white),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        body: Column(
          children: [
            // Top Section Tabs Bar
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

            // Question Page View Content
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

            // --- INLINE QUESTION PALETTE AREA (Save & Next Ke Thik Upar) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle Bar for Palette Expansion
                  InkWell(
                    onTap: () => setState(() => _isPaletteExpanded = !_isPaletteExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.indigo.shade50,
                      child: Row(
                        children: [
                          Icon(_isPaletteExpanded ? Icons.keyboard_arrow_down : Icons.grid_view, size: 18, color: const Color(0xFF1A237E)),
                          const SizedBox(width: 8),
                          Text(
                            'Question Palette (${currentQuestionIndex + 1}/${questions.length})',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                          ),
                          const Spacer(),
                          Icon(_isPaletteExpanded ? Icons.expand_more : Icons.expand_less, color: const Color(0xFF1A237E)),
                        ],
                      ),
                    ),
                  ),

                  // Collapsible Grid View and Badges
                  if (_isPaletteExpanded)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildLegendBadge(Colors.green, '${questionStatuses.where((s) => s == QuestionStatus.answered).length} Ans'),
                              _buildLegendBadge(Colors.purple, '${questionStatuses.where((s) => s == QuestionStatus.markedForReview).length} Marked'),
                              _buildLegendBadge(Colors.grey.shade300, '${questionStatuses.where((s) => s == QuestionStatus.notVisited).length} Unvisited', textColor: Colors.black),
                              _buildLegendBadge(Colors.blue, '${questionStatuses.where((s) => s == QuestionStatus.markedAndAnswered).length} Ans & Mark'),
                              _buildLegendBadge(Colors.red, '${questionStatuses.where((s) => s == QuestionStatus.notAnswered).length} Not Ans'),
                            ],
                          ),
                          const Divider(height: 10),
                          Expanded(
                            child: GridView.builder(
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
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

                                final isCurrent = currentQuestionIndex == index;

                                return InkWell(
                                  onTap: () {
                                    _navigateToQuestion(index);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: isCurrent ? Border.all(color: Colors.amber, width: 2) : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // --- BOTTOM NAVIGATION ACTION BUTTONS ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: currentQuestionIndex > 0 ? () => _navigateToQuestion(currentQuestionIndex - 1) : null,
                      child: const Text('Previous', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purple), padding: EdgeInsets.zero),
                      onPressed: _markForReviewAndNext,
                      child: const Text('Mark & Save', style: TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: EdgeInsets.zero),
                      onPressed: _clearResponse,
                      child: const Text('Clear', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
      ),
    );
  }
}

// Helper String extension method for formatting time safely
extension StringPadExtension on String {
  String toStringAndPadLeft(int width, String padding) {
    return padLeft(width, padding);
  }
}
