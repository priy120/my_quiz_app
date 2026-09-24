import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sub_categories_screen.dart';
import 'plans_screen.dart';

class ExamCategoriesScreen extends StatefulWidget {
  const ExamCategoriesScreen({super.key});

  @override
  State<ExamCategoriesScreen> createState() => _ExamCategoriesScreenState();
}

class _ExamCategoriesScreenState extends State<ExamCategoriesScreen> {
  final Map<String, String> _categoryLogos = const {
    'SSC': 'https://upload.wikimedia.org/wikipedia/commons/d/d4/Staff_Selection_Commission_Logo.png',
    'RAILWAYS': 'https://upload.wikimedia.org/wikipedia/en/thumb/4/45/Indian_Railways_logo.svg/1200px-Indian_Railways_logo.svg.png',
    'IB': 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Intelligence_Bureau_India_Logo.png',
    'UPPPBP': 'https://upload.wikimedia.org/wikipedia/commons/e/ea/Uttar_Pradesh_Police_Seal.png',
    'RPF': 'https://upload.wikimedia.org/wikipedia/en/f/f3/Railway_Protection_Force_India_Logo.png',
    'DELHI POLICE': 'https://upload.wikimedia.org/wikipedia/en/d/d4/Delhi_Police_Logo.png',
    'DEFENCE': 'https://upload.wikimedia.org/wikipedia/commons/5/53/Emblem_of_India.svg',
    'BANKING': 'https://upload.wikimedia.org/wikipedia/commons/c/cc/SBI-Logo.svg',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Test Series',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('exam_categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          final List<String> categories = docs.isNotEmpty
              ? docs.map((d) => d.id.toUpperCase()).toList()
              : ['SSC', 'RAILWAYS', 'IB', 'UPPPBP', 'RPF', 'DELHI POLICE', 'DEFENCE', 'BANKING'];

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final catName = categories[index];
                    final logoUrl = _categoryLogos[catName] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
                    
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubCategoriesScreen(categoryName: catName),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                catName,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Image.network(
                              logoUrl,
                              width: 34,
                              height: 34,
                              errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.indigo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom Buy Now Pass Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1A237E),
                child: SafeArea(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlansScreen()),
                      );
                    },
                    child: const Text(
                      'Buy Now Pass',
                      style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
