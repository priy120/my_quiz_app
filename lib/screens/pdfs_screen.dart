import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfScreen extends StatelessWidget {
  const PdfScreen({super.key});

  final List<Map<String, String>> pdfList = const [
    {
      'title': 'SSC CGL & CHSL General Awareness Notes 2026',
      'size': '4.2 MB',
      'category': 'General Knowledge',
      'date': '18 Sep 2026',
    },
    {
      'title': 'Complete Maths Formula Sheet (Algebra + Geometry)',
      'size': '2.8 MB',
      'category': 'Mathematics',
      'date': '15 Sep 2026',
    },
    {
      'title': 'UP Police Constable Special GS & Hindi Quick Revision',
      'size': '5.1 MB',
      'category': 'State Exams',
      'date': '10 Sep 2026',
    },
    {
      'title': 'Reasoning Top 500 Tricks & Short Cut Key Sheet',
      'size': '3.6 MB',
      'category': 'Reasoning',
      'date': '05 Sep 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: pdfList.length,
        itemBuilder: (context, index) {
          final pdf = pdfList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              title: Text(
                pdf['title']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pdf['category']!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${pdf['size']} • ${pdf['date']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download_rounded, color: Color(0xFF1A237E)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Downloading ${pdf['title']}..."),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
