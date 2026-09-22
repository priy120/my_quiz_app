import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'solutions_screen.dart';

class AnalysisScreen extends StatelessWidget {
  final String testId;
  final String testTitle;
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;

  const AnalysisScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
  });

  @override
  Widget build(BuildContext context) {
    final int attempted = correctCount + wrongCount;
    final double accuracy = attempted > 0 ? (correctCount / attempted) * 100 : 0.0;
    final int totalMarks = totalQuestions * 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Test Performance Analysis',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SolutionsScreen(
                    testId: testId,
                    testTitle: testTitle,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('SOLUTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Performance Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL PERFORMANCE',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Divider(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.2,
                      children: [
                        _buildMetricTile('Score', '${score.toStringAsFixed(1)} / $totalMarks', Icons.emoji_events, Colors.amber.shade800),
                        _buildMetricTile('Accuracy', '${accuracy.toStringAsFixed(1)}%', Icons.track_changes, Colors.blue),
                        _buildMetricTile('Attempted', '$attempted / $totalQuestions', Icons.assignment_turned_in, Colors.indigo),
                        _buildMetricTile('Correct / Wrong', '$correctCount / $wrongCount', Icons.rate_review, Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Solutions Quick Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF1A237E), Colors.indigo.shade600]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check Detailed Solutions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('View step-by-step answers & explanations', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SolutionsScreen(
                            testId: testId,
                            testTitle: testTitle,
                          ),
                        ),
                      );
                    },
                    child: const Text('VIEW SOLUTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Leaderboard / Rank List
            Text(
              'Top Rankers (Leaderboard)',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaderboards')
                  .doc(testId)
                  .collection('ranks')
                  .orderBy('score', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final rankDocs = snapshot.data!.docs;

                if (rankDocs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("No rank data available yet.")),
                    ),
                  );
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rankDocs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = rankDocs[index].data() as Map<String, dynamic>;
                      final name = data['userName'] ?? 'Student';
                      final rankScore = data['score'] ?? 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey.shade400 : (index == 2 ? Colors.brown.shade300 : Colors.indigo.shade50)),
                          child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        trailing: Text('${rankScore.toStringAsFixed(1)} Marks', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
