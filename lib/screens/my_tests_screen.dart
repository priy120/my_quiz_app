import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_engine_screen.dart';

class MyTestsScreen extends StatelessWidget {
  const MyTestsScreen({super.key});

  final List<Map<String, String>> attemptedTests = const [
    {
      'title': 'UP Police Constable Full Mock Test - 01',
      'score': '240 / 300',
      'status': 'Completed',
      'date': '19 Sep 2026',
    },
    {
      'title': 'SSC CGL Tier-1 All India Live Mock Test',
      'score': '142 / 200',
      'status': 'Completed',
      'date': '16 Sep 2026',
    },
    {
      'title': 'RRB NTPC CBT-1 Special Practice Test',
      'score': 'Pending',
      'status': 'In Progress',
      'date': '20 Sep 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: attemptedTests.length,
        itemBuilder: (context, index) {
          final test = attemptedTests[index];
          final isCompleted = test['status'] == 'Completed';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          test['status']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      Text(
                        test['date']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    test['title']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score: ${test['score']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? const Color(0xFF1A237E)
                              : Colors.grey.shade700,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuizEngineScreen(),
                            ),
                          );
                        },
                        child: Text(
                          isCompleted ? 'RE-ATTEMPT' : 'RESUME TEST',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
