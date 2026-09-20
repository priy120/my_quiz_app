import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizEngineScreen extends StatefulWidget {
  const QuizEngineScreen({super.key});

  @override
  State<QuizEngineScreen> createState() => _QuizEngineScreenState();
}

class _QuizEngineScreenState extends State<QuizEngineScreen> {
  int currentQuestionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 600; // 10 Minutes Timer

  final List<Map<String, dynamic>> questions = [
    {
      'section': 'General Knowledge',
      'question': 'What is the capital of India?',
      'options': ['Mumbai', 'New Delhi', 'Kolkata', 'Chennai'],
      'correctIndex': 1,
    },
    {
      'section': 'General Knowledge',
      'question': 'Which planet is known as the Red Planet?',
      'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      'correctIndex': 1,
    },
    {
      'section': 'Mathematics',
      'question': 'What is the value of (12 x 12) / 4?',
      'options': ['24', '36', '48', '144'],
      'correctIndex': 1,
    },
    {
      'section': 'Mathematics',
      'question': 'What is the derivative of x^2 with respect to x?',
      'options': ['x', '2x', 'x^2', '2'],
      'correctIndex': 1,
    },
    {
      'section': 'Reasoning',
      'question': 'If A = 1, B = 2, C = 3, then CAT = ?',
      'options': ['24', '20', '21', '22'],
      'correctIndex': 0,
    },
  ];

  late List<int?> selectedAnswers;
  late List<bool> isMarkedForReview;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List<int?>.filled(questions.length, null);
    isMarkedForReview = List<bool>.filled(questions.length, false);
    _startTimer();
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

  void _submitTest() {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              'Test Submitted! 🎉',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: ${totalScore < 0 ? 0 : totalScore} / ${questions.length * 2}',
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
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Exit Quiz Screen
            },
            child: const Text('BACK TO DASHBOARD', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  void _openQuestionPalette() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Palette',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: questions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  Color btnColor = Colors.grey.shade300;
                  Color textColor = Colors.black;

                  if (selectedAnswers[index] != null) {
                    btnColor = Colors.green;
                    textColor = Colors.white;
                  } else if (isMarkedForReview[index]) {
                    btnColor = Colors.purple;
                    textColor = Colors.white;
                  }

                  if (currentQuestionIndex == index) {
                    btnColor = const Color(0xFF1A237E);
                    textColor = Colors.white;
                  }

                  return InkWell(
                    onTap: () {
                      setState(() => currentQuestionIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: btnColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: Text(
          'CompeteMe Live Mock Test',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentQuestion['question'],
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion['options'].length,
                itemBuilder: (context, optIndex) {
                  final isSelected = selectedAnswers[currentQuestionIndex] == optIndex;

                  return Card(
                    elevation: isSelected ? 3 : 1,
                    color: isSelected ? Colors.indigo.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300,
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
                    child: const Text('Next Question', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: _submitTest,
                    child: const Text('Submit Test', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
