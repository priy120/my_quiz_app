import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package01/google_fonts/google_fonts.dart';
import 'package:google_fonts/google_fonts.dart';

class SolutionsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const SolutionsScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSolutions();
  }

  Future<void> _fetchSolutions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .collection('questions')
          .orderBy('questionNo', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _questions = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Solutions: ${widget.testTitle}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text("No solutions data found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final questionText = q['questionText'] ?? '';
                    final options = List<String>.from(q['options'] ?? []);
                    final correctIndex = q['correctIndex'] ?? 0;
                    final solutionText = q['solutionText'] ?? 'No detailed explanation available.';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
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
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Q. ${index + 1} (${q['section'] ?? 'General'})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              questionText,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: List.generate(options.length, (optIdx) {
                                final isCorrect = optIdx == correctIndex;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCorrect ? Colors.green.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCorrect ? Colors.green : Colors.grey.shade300,
                                      width: isCorrect ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isCorrect ? Colors.green : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          options[optIdx],
                                          style: TextStyle(
                                            color: isCorrect ? Colors.green.shade900 : Colors.black87,
                                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Explanation / Solution:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    solutionText,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
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
