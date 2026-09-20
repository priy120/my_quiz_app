import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedTab = 0; // 0 = PDF, 1 = Create Test, 2 = JSON Bulk Upload

  // PDF Controllers
  final _pdfTitleController = TextEditingController();
  final _pdfCategoryController = TextEditingController();
  final _pdfSizeController = TextEditingController();
  final _pdfUrlController = TextEditingController();

  // Mock Test Package Controllers
  final _testTitleController = TextEditingController();
  final _testCategoryController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _totalMarksController = TextEditingController();

  // JSON Bulk Upload Controller
  String? _selectedTestId;
  final _jsonTextController = TextEditingController();

  bool _isLoading = false;

  // 1. Upload PDF
  Future<void> _uploadPdf() async {
    if (_pdfTitleController.text.isEmpty || _pdfUrlController.text.isEmpty) {
      _showSnackbar('Please fill Title and File URL');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pdfs').add({
        'title': _pdfTitleController.text.trim(),
        'category': _pdfCategoryController.text.trim().isEmpty
            ? 'General'
            : _pdfCategoryController.text.trim(),
        'size': _pdfSizeController.text.trim().isEmpty
            ? '2.5 MB'
            : _pdfSizeController.text.trim(),
        'url': _pdfUrlController.text.trim(),
        'date': '2026',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('PDF Uploaded Successfully!', isSuccess: true);
      _pdfTitleController.clear();
      _pdfCategoryController.clear();
      _pdfSizeController.clear();
      _pdfUrlController.clear();
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Create Full Mock Package
  Future<void> _createFullMockTest() async {
    if (_testTitleController.text.isEmpty) {
      _showSnackbar('Please enter Mock Test Title');
      return;
    }

    setState(() => _isLoading = true);

    try {
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('mock_tests').add({
        'title': _testTitleController.text.trim(),
        'category': _testCategoryController.text.trim().isEmpty
            ? 'General'
            : _testCategoryController.text.trim(),
        'durationMinutes':
            int.tryParse(_durationMinutesController.text.trim()) ?? 60,
        'totalMarks': int.tryParse(_totalMarksController.text.trim()) ?? 100,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar(
          'Mock Test Package Created! Select it in JSON Upload tab.',
          isSuccess: true);

      setState(() {
        _selectedTestId = docRef.id;
        _selectedTab = 2; // Jump to JSON Bulk Upload
      });

      _testTitleController.clear();
      _testCategoryController.clear();
      _durationMinutesController.clear();
      _totalMarksController.clear();
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. JSON Bulk Upload Questions
  Future<void> _uploadJsonQuestions() async {
    if (_selectedTestId == null) {
      _showSnackbar('Please select a Mock Test first!');
      return;
    }
    if (_jsonTextController.text.trim().isEmpty) {
      _showSnackbar('Please paste JSON text code!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<dynamic> parsedList = json.decode(_jsonTextController.text.trim());

      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(_selectedTestId)
          .collection('questions');

      for (var item in parsedList) {
        final docRef = collectionRef.doc();
        batch.set(docRef, {
          'questionNo': item['questionNo'] ?? 1,
          'section': item['section'] ?? 'General',
          'questionText': item['questionText'] ?? '',
          'imageUrl': item['imageUrl'] ?? '',
          'options': List<String>.from(item['options'] ?? []),
          'correctIndex': item['correctIndex'] ?? 0,
          'solutionText': item['solutionText'] ?? '',
          'solutionImageUrl': item['solutionImageUrl'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _showSnackbar(
          'SUCCESS! ${parsedList.length} Questions Imported via JSON!',
          isSuccess: true);
      _jsonTextController.clear();
    } catch (e) {
      _showSnackbar('JSON Parsing Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CompeteMe Admin Portal',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(0, 'Upload PDF'),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Create Test Package'),
                  const SizedBox(width: 8),
                  _buildTabButton(2, 'JSON Bulk Upload'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedTab == 0) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Upload PDF Document',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _pdfTitleController,
                          decoration: const InputDecoration(
                              labelText: 'PDF Title (e.g. GS Quick Revision)')),
                      TextField(
                          controller: _pdfCategoryController,
                          decoration: const InputDecoration(
                              labelText: 'Category (e.g. State Exams)')),
                      TextField(
                          controller: _pdfSizeController,
                          decoration: const InputDecoration(
                              labelText: 'File Size (e.g. 4.2 MB)')),
                      TextField(
                          controller: _pdfUrlController,
                          decoration: const InputDecoration(
                              labelText: 'Drive / PDF Link')),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E)),
                          onPressed: _isLoading ? null : _uploadPdf,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('POST PDF TO APP',
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedTab == 1) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Create Mock Test Package Header',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _testTitleController,
                        decoration: const InputDecoration(
                            labelText:
                                'Test Title (e.g. UP Police Constable Mock 01)'),
                      ),
                      TextField(
                        controller: _testCategoryController,
                        decoration: const InputDecoration(
                            labelText: 'Category (e.g. UP Police)'),
                      ),
                      TextField(
                        controller: _durationMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Duration Minutes (e.g. 120)'),
                      ),
                      TextField(
                        controller: _totalMarksController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Total Marks (e.g. 300)'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E)),
                          onPressed: _isLoading ? null : _createFullMockTest,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('CREATE PACKAGE & NEXT',
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedTab == 2) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('JSON Bulk Upload (100+ Questions)',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('mock_tests')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final tests = snapshot.data!.docs;

                          return DropdownButtonFormField<String>(
                            value: _selectedTestId,
                            hint: const Text('Select Target Mock Test'),
                            isExpanded: true,
                            items: tests.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(data['title'] ?? 'Mock Test'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTestId = val),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _jsonTextController,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          hintText: 'Paste JSON Code Array here...\n[\n  {\n    "questionText": "...",\n    "options": ["A", "B", "C", "D"],\n    "correctIndex": 0\n  }\n]',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700),
                          onPressed: _isLoading ? null : _uploadJsonQuestions,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('UPLOAD ALL QUESTIONS VIA JSON',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    bool isSelected = _selectedTab == index;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300,
      ),
      onPressed: () => setState(() => _selectedTab = index),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
