import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'battle_screen.dart';

class BattleCategoryScreen extends StatefulWidget {
  const BattleCategoryScreen({super.key});

  @override
  State<BattleCategoryScreen> createState() => _BattleCategoryScreenState();
}

class _BattleCategoryScreenState extends State<BattleCategoryScreen> {
  bool _isLoading = false;

  Future<void> _startBattleCategory(String categoryName, String categoryId) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Fetch Question Pool from Firestore using dynamic categoryId
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('battle_questions')
          .doc(categoryId)
          .get();

      if (!doc.exists || doc.data() == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No questions found for $categoryName yet! Add from Admin Panel."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      var data = doc.data() as Map<String, dynamic>;
      List rawQuestions = data['questions'] ?? [];

      if (rawQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No questions available in $categoryName."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      List<Map<String, dynamic>> allQuestions =
          List<Map<String, dynamic>>.from(rawQuestions);

      // 2. Fetch Previously Played Questions History for User
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

      // 3. Filter Non-Repeated Fresh Questions
      List<Map<String, dynamic>> freshQuestions = allQuestions
          .where((q) => !playedQuestionTexts.contains(q['questionText']))
          .toList();

      // If user played all questions, fallback to entire pool
      if (freshQuestions.length < 5) {
        freshQuestions = List.from(allQuestions);
      }

      freshQuestions.shuffle();
      if (freshQuestions.length > 10) {
        freshQuestions = freshQuestions.sublist(0, 10);
      }

      // Save new set to user history
      if (user != null) {
        List<String> newTexts =
            freshQuestions.map((e) => e['questionText'].toString()).toList();
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'played_battle_questions': FieldValue.arrayUnion(newTexts)
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BattleScreen(
              testTitle: categoryName,
              questions: freshQuestions,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching battle: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: Text(
          'Select Battle Arena ⚔️️',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1A237E)),
                  SizedBox(height: 16),
                  Text("Preparing Arena & Fresh Questions..."),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Subject',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compete live with players or AI bot in real-time speed rounds.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DYNAMIC CATEGORIES STREAM FROM FIRESTORE
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('battle_categories')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.category_outlined,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  "No Battle Categories Available Yet.\nAdd one from Admin Panel!",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        var docs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var catData =
                                docs[index].data() as Map<String, dynamic>;
                            String name = catData['name'] ?? 'Battle Quiz';
                            String docId = catData['id'] ?? docs[index].id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      const Color(0xFF1A237E).withOpacity(0.1),
                                  child: const Icon(Icons.flash_on,
                                      color: Color(0xFF1A237E)),
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  "10 Rapid Speed Questions • 1v1 Mode",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Color(0xFF1A237E)),
                                onTap: () =>
                                    _startBattleCategory(name, docId),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
