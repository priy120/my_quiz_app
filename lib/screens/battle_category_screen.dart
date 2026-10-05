import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'battle_screen.dart';

class BattleCategoryScreen extends StatefulWidget {
  const BattleCategoryScreen({super.key});

  @override
  State<BattleCategoryScreen> createState() => _BattleCategoryScreenState();
}

class _BattleCategoryScreenState extends State<BattleCategoryScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Speed Mathematics',
      'subtitle': 'Arithmetic & Calculation',
      'icon': Icons.calculate_outlined,
      'color': Colors.orange,
      'docId': 'maths',
    },
    {
      'title': 'Hindi Grammar',
      'subtitle': 'वर्णमाला, संधि, समास',
      'icon': Icons.menu_book_outlined,
      'color': Colors.indigo,
      'docId': 'hindi',
    },
    {
      'title': 'General Knowledge',
      'subtitle': 'UP GK, History & Polity',
      'icon': Icons.public_outlined,
      'color': Colors.green,
      'docId': 'gk',
    },
    {
      'title': 'Reasoning Ability',
      'subtitle': 'Coding, Series & Logic',
      'icon': Icons.psychology_outlined,
      'color': Colors.purple,
      'docId': 'reasoning',
    },
  ];

  Future<void> _startBattleForCategory(String title, String docId) async {
    setState(() => _isLoading = true);

    try {
      // Fetch questions for selected subject from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('battle_questions')
          .doc(docId)
          .get();

      if (!doc.exists || doc.data() == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title ke questions abhi available nahi hain!")),
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
            const SnackBar(content: Text("No questions found in database!")),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Convert to List<Map<String, dynamic>>
      List<Map<String, dynamic>> fetchedQuestions =
          List<Map<String, dynamic>>.from(rawQuestions);

      // Shuffle for randomness & pick first 10
      fetchedQuestions.shuffle();
      if (fetchedQuestions.length > 10) {
        fetchedQuestions = fetchedQuestions.sublist(0, 10);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BattleScreen(
              testTitle: title,
              questions: fetchedQuestions,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching battle questions: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server error! Please try again.")),
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
        title: Text(
          "Select Battle Arena ⚔️",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1A237E)),
                  const SizedBox(height: 16),
                  Text("Preparing Questions Arena...", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                var cat = _categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: (cat['color'] as Color).withOpacity(0.15),
                      child: Icon(cat['icon'], color: cat['color'], size: 26),
                    ),
                    title: Text(
                      cat['title'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      cat['subtitle'],
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.indigo),
                    onTap: () => _startBattleForCategory(cat['title'], cat['docId']),
                  ),
                );
              },
            ),
    );
  }
}
