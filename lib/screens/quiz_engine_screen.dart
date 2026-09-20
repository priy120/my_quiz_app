import 'dart:async';
import 'package:flutter/material.dart';

class QuizEngineScreen extends StatefulWidget {
  const QuizEngineScreen({super.key});

  @override
  State<QuizEngineScreen> createState() => _QuizEngineScreenState();
}

class _QuizEngineScreenState extends State<QuizEngineScreen> {
  int _secondsLeft = 600; // 10 Min Timer
  Timer? _timer;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Q1. What is the capital of India?',
      'options': ['Mumbai', 'New Delhi', 'Kolkata', 'Chennai'],
      'correctIndex': 1,
    },
    {
      'question': 'Q2. Which planet is known as the Red Planet?',
      'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      'correctIndex': 1,
    },
    {
      'question': 'Q3. What is the derivative of x^2 with respect to x?',
      'options': ['x', '2x', 'x^2', '2'],
      'correctIndex': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitTest() {
    _timer?.cancel();
    int score = 0;
    _selectedAnswers.forEach((qIndex, selectedOpt) {
      if (_questions[qIndex]['correctIndex'] == selectedOpt) {
        score++;
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Submitted 🎉'),
        content: Text('Your Score: $score / ${_questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentQuestionIndex];
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('RWA Live Mock Test'),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⏱ $minutes:$seconds',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF1A237E),
            ),
            const SizedBox(height: 20),
            Text(
              currentQ['question'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              (currentQ['options'] as List).length,
              (optIndex) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedAnswers[_currentQuestionIndex] == optIndex
                        ? const Color(0xFF1A237E)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RadioListTile<int>(
                  title: Text(currentQ['options'][optIndex]),
                  value: optIndex,
                  groupValue: _selectedAnswers[_currentQuestionIndex],
                  onChanged: (val) {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = val!;
                    });
                  },
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentQuestionIndex--),
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                    onPressed: () => setState(() => _currentQuestionIndex++),
                    child: const Text('Next Question', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: _submitTest,
                    child: const Text('Submit Test', style: TextStyle(color: Colors.white)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
