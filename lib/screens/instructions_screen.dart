import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_engine_screen.dart';

class InstructionsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final int durationMinutes;
  final int totalMarks;

  const InstructionsScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    this.durationMinutes = 60,
    this.totalMarks = 200,
  });

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  String _selectedLanguage = 'Hindi';
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.testTitle,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Instructions:',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 10),
                  const Text('1. The countdown timer in the top right corner will display the remaining time available.'),
                  const SizedBox(height: 6),
                  Text('2. Total Duration: ${widget.durationMinutes} Minutes. Total Marks: ${widget.totalMarks}.'),
                  const SizedBox(height: 6),
                  const Text('3. Each correct answer carries positive marks, while wrong answers may carry negative marking.'),
                  const SizedBox(height: 6),
                  const Text('4. You can switch between sections freely during the exam.'),
                  const Divider(height: 30),
                  Text(
                    'Choose Default Language:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi / हिंदी')),
                      DropdownMenuItem(value: 'English', child: Text('English')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        activeColor: const Color(0xFF1A237E),
                        onChanged: (val) => setState(() => _isAgreed = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'I have read and understood all instructions and agree to proceed.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAgreed ? const Color(0xFF1A237E) : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isAgreed
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizEngineScreen(
                              testId: widget.testId,
                              testTitle: widget.testTitle,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('START TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
