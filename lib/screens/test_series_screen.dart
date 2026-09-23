import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'instructions_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _selectedCategory == null ? 'Test Series Categories' : '$_selectedCategory Tests',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : null,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: _selectedCategory == null ? _buildCategoryGrid() : _buildTestList(),
    );
  }

  // Level 1: Category Grid Cards (SSC, Railways, UP Police, etc.)
  Widget _buildCategoryGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('exam_categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No exam categories created in Admin Panel yet."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final categoryName = docs[index].id;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = categoryName),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, color: Color(0xFF1A237E), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        categoryName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Level 2: Selected Category Tests List
  Widget _buildTestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mock_tests')
          .where('category', isEqualTo: _selectedCategory)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text("No tests uploaded for $_selectedCategory yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Mock Test';
            final duration = data['durationMinutes'] ?? 60;
            final marks = data['totalMarks'] ?? 200;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('$duration Mins  •  $marks Marks'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InstructionsScreen(
                          testId: doc.id,
                          testTitle: title,
                          durationMinutes: duration,
                          totalMarks: marks,
                        ),
                      ),
                    );
                  },
                  child: const Text('START', style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
