import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'battle_screen.dart';

class BattleAnalysisScreen extends StatelessWidget {
  final String testTitle;
  final int myScore;
  final int oppScore;
  final String oppName;
  final List<Map<String, dynamic>> questions;
  final List<int?> myAnswers;

  const BattleAnalysisScreen({
    super.key,
    required this.testTitle,
    required this.myScore,
    required this.oppScore,
    required this.oppName,
    required this.questions,
    required this.myAnswers,
  });

  @override
  Widget build(BuildContext context) {
    bool isWin = myScore > oppScore;
    bool isDraw = myScore == oppScore;

    int totalQs = questions.length;
    int myCorrect = 0;
    int myWrong = 0;
    int myUnattempted = 0;

    for (int i = 0; i < myAnswers.length; i++) {
      if (myAnswers[i] == null || myAnswers[i] == -1) {
        myUnattempted++;
      } else if (myAnswers[i] == questions[i]['correctIndex']) {
        myCorrect++;
      } else {
        myWrong++;
      }
    }

    double myAccuracy = totalQs > 0 ? ((myCorrect / totalQs) * 100) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: Text("Battle Analysis & Review 📊", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RESULT HEADER BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWin ? Colors.green.shade700 : (isDraw ? Colors.orange.shade700 : Colors.red.shade700),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    isWin ? Icons.emoji_events : (isDraw ? Icons.handshake : Icons.sentiment_dissatisfied),
                    color: Colors.amber,
                    size: 48,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isWin ? "YOU WON THE BATTLE! 🏆" : (isDraw ? "MATCH DRAW! 🤝" : "YOU LOST THE BATTLE! ❌"),
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreBox("Your Score", "$myScore pts", Colors.white),
                      Text("VS", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
                      _buildScoreBox(oppName, "$oppScore pts", Colors.white70),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. GAP ANALYSIS
            Text("Battle Insights & Key Takeaways", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            _buildGapAnalysisCard(isWin, isDraw, myCorrect, myWrong, myUnattempted, myScore, oppScore, oppName),
            const SizedBox(height: 20),

            // 3. STATS SUMMARY
            Text("Performance Breakdown", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol("Accuracy", "${myAccuracy.toStringAsFixed(0)}%", Colors.indigo),
                    _buildStatCol("Correct", "$myCorrect", Colors.green),
                    _buildStatCol("Wrong", "$myWrong", Colors.redAccent),
                    _buildStatCol("Skipped", "$myUnattempted", Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. QUESTION BY QUESTION REVIEW
            Text("Question-by-Question Review", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                var q = questions[index];
                int? userAns = myAnswers.length > index ? myAnswers[index] : null;
                int correctAns = q['correctIndex'] ?? 0;
                List opts = q['options'] is List ? q['options'] : (q['options'] as Map).values.toList();

                bool isCorrect = userAns == correctAns;
                bool isUnattempted = userAns == null || userAns == -1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isCorrect
                                  ? Colors.green
                                  : (isUnattempted ? Colors.orange : Colors.red),
                              child: Icon(
                                isCorrect
                                    ? Icons.check
                                    : (isUnattempted ? Icons.remove : Icons.close),
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("Q${index + 1}.", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(q['questionText'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(opts.length, (optIdx) {
                            Color textColor = Colors.black87;
                            FontWeight weight = FontWeight.normal;

                            if (optIdx == correctAns) {
                              textColor = Colors.green.shade800;
                              weight = FontWeight.bold;
                            } else if (optIdx == userAns) {
                              textColor = Colors.red.shade800;
                              weight = FontWeight.bold;
                            }

                            return Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: optIdx == correctAns
                                    ? Colors.green.shade50
                                    : (optIdx == userAns ? Colors.red.shade50 : Colors.transparent),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Text("${String.fromCharCode(65 + optIdx)}. ${opts[optIdx]}",
                                      style: GoogleFonts.poppins(color: textColor, fontWeight: weight, fontSize: 12)),
                                  if (optIdx == correctAns)
                                    const Text("  ✓ (Correct Answer)", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  if (optIdx == userAns && !isCorrect)
                                    const Text("  ✗ (Your Choice)", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 5. ACTION BUTTONS (EXIT & NEW BATTLE)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text("Exit Arena", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.bolt, color: Colors.amber),
                    label: Text("NEW BATTLE ⚔️️", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                      );

                      try {
                        final user = FirebaseAuth.instance.currentUser;

                        // Dynamic Category Resolution from Categories Collection
                        QuerySnapshot catSnap = await FirebaseFirestore.instance
                            .collection('battle_categories')
                            .get();

                        String matchedDocId = 'maths'; // Default Fallback
                        for (var doc in catSnap.docs) {
                          var catData = doc.data() as Map<String, dynamic>;
                          String catName = catData['name'] ?? '';
                          if (catName.toLowerCase() == testTitle.toLowerCase() ||
                              testTitle.toLowerCase().contains(doc.id.toLowerCase())) {
                            matchedDocId = doc.id;
                            break;
                          }
                        }

                        // Fetch Question Pool from Firestore
                        DocumentSnapshot doc = await FirebaseFirestore.instance
                            .collection('battle_questions')
                            .doc(matchedDocId)
                            .get();

                        // Fetch User Played History
                        List playedQuestionTexts = [];
                        if (user != null) {
                          DocumentSnapshot userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();
                          if (userDoc.exists && userDoc.data() != null) {
                            Map userData = userDoc.data() as Map;
                            playedQuestionTexts = userData['played_battle_questions'] ?? [];
                          }
                        }

                        if (context.mounted) Navigator.pop(context); // Close loading

                        if (doc.exists && doc.data() != null) {
                          var data = doc.data() as Map<String, dynamic>;
                          List rawQuestions = data['questions'] ?? [];

                          List<Map<String, dynamic>> allQuestions =
                              List<Map<String, dynamic>>.from(rawQuestions);

                          // Filter out previously seen questions
                          List<Map<String, dynamic>> freshQuestions = allQuestions
                              .where((q) => !playedQuestionTexts.contains(q['questionText']))
                              .toList();

                          // If user played almost all questions, fallback to entire pool
                          if (freshQuestions.length < 5) {
                            freshQuestions = List.from(allQuestions);
                          }

                          freshQuestions.shuffle();
                          if (freshQuestions.length > 10) {
                            freshQuestions = freshQuestions.sublist(0, 10);
                          }

                          // Save new set to user history to avoid future repetition
                          if (user != null) {
                            List<String> newTexts =
                                freshQuestions.map((e) => e['questionText'].toString()).toList();
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                              'played_battle_questions': FieldValue.arrayUnion(newTexts)
                            }, SetOptions(merge: true));
                          }

                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BattleScreen(
                                  testTitle: testTitle,
                                  questions: freshQuestions,
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error fetching next battle: $e")),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBox(String label, String score, Color textColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 12)),
        Text(score, style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildStatCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildGapAnalysisCard(bool isWin, bool isDraw, int correct, int wrong, int unattempted, int myScore, int oppScore, String oppName) {
    String message = "";
    IconData icon = Icons.info;
    Color cardColor = Colors.blue.shade50;

    if (isWin) {
      message = "Brilliant Performance! Aapne accuracy aur speed dono me opponent ko dominate kiya.";
      icon = Icons.star;
      cardColor = Colors.green.shade50;
    } else if (wrong > 2) {
      message = "Aap $wrong galat uttar hone ki वजह se piche reh gaye. Galat attempt karne se streak bonus tut gaya.";
      icon = Icons.warning_amber;
      cardColor = Colors.red.shade50;
    } else if (unattempted > 1) {
      message = "Aapne $unattempted questions time out hone ki वजह se miss kar diye. Speed improve karein!";
      icon = Icons.timer;
      cardColor = Colors.orange.shade50;
    } else {
      message = "Match kafi close tha! Opponent ne combo multipliers ki वजह se lead li.";
      icon = Icons.trending_up;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.indigo, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.indigo.shade900, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
