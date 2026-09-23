import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'solutions_screen.dart';
import 'quiz_engine_screen.dart';

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

  void _showSolutionInterfaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Solution Interface Selection',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Which solution interface you want to use?', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              title: const Text('New Pattern (Eduquity)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SolutionsScreen(testId: testId, testTitle: testTitle)));
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              title: const Text('Old Pattern (TCS)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SolutionsScreen(testId: testId, testTitle: testTitle)));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int attempted = correctCount + wrongCount;
    final double accuracy = attempted > 0 ? (correctCount / attempted) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Analysis', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            ),
            onPressed: () => _showSolutionInterfaceDialog(context),
            child: const Text('Solution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expert Comment Card from Video
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Expert comment', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Attempt 1', style: TextStyle(fontSize: 10, color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 11, height: 1.3),
                              children: [
                                const TextSpan(text: 'Dear '),
                                TextSpan(text: 'Priyanshu', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                                const TextSpan(text: ', Not a good performance! Practice Hard and focus on your weak topics mentioned below!'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid (Rank, Score, Accuracy, Percentile, Attempted, Time)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OVERALL PERFORMANCE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Cut Off : 40.00', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildMetricCard('Rank', '13824/13846', Icons.emoji_events, Colors.amber),
                _buildMetricCard('Score', '${score.toStringAsFixed(2)} / 50', Icons.score, Colors.red),
                _buildMetricCard('Accuracy', '${accuracy.toStringAsFixed(2)}%', Icons.track_changes, Colors.green),
                _buildMetricCard('Percentile', '0.2%', Icons.pie_chart, Colors.orange),
                _buildMetricCard('Attempted', '$attempted / $totalQuestions', Icons.help_outline, Colors.blue),
                _buildMetricCard('Time Spent', '0.13 / 15.0', Icons.timer, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            // Section Wise Performance
            Text('SECTION WISE PERFORMANCE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                      child: const Text('PART-B (General Intelligence)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1A237E))),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Score', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        Text('${score.toStringAsFixed(1)} / 50.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Attempted', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        Text('$attempted / $totalQuestions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Accuracy', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        Text('${accuracy.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Weak Topics & Strong Topics
            Text('WEAK TOPICS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('Analogy', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFFFFEBEE)),
                Chip(label: Text('Coding-Decoding', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFFFFEBEE)),
                Chip(label: Text('Syllogism', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFFFFEBEE)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(val, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
