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
  int _selectedTab = 0;
  bool _isLoading = false;

  // Category Manager Controller
  final TextEditingController _newCategoryController = TextEditingController();

  // Test Creation Controllers
  final TextEditingController _testTitleController = TextEditingController();
  final TextEditingController _durationMinutesController = TextEditingController(text: '60');
  final TextEditingController _totalMarksController = TextEditingController(text: '200');
  final TextEditingController _pyqYearController = TextEditingController(text: '2025');
  final TextEditingController _pyqShiftController = TextEditingController(text: 'Shift 1');

  String? _selectedCategory;
  String _selectedTestType = 'Full Mock'; // Full Mock, PYQ, Sectional
  bool _isFreeTest = false;

  final List<String> _testTypes = ['Full Mock', 'PYQ', 'Sectional'];

  // JSON Upload Controllers
  final TextEditingController _jsonInputController = TextEditingController();
  String? _selectedTestId;

  // PDF Upload Controllers
  final TextEditingController _pdfTitleController = TextEditingController();
  final TextEditingController _pdfCategoryController = TextEditingController();
  final TextEditingController _pdfSizeController = TextEditingController();
  final TextEditingController _pdfUrlController = TextEditingController();

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  // Add Dynamic Category
  Future<void> _addCategory() async {
    final catName = _newCategoryController.text.trim();
    if (catName.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('exam_categories').doc(catName).set({
        'name': catName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _newCategoryController.clear();
      _showSnackbar('Category "$catName" Added!', isSuccess: true);
    } catch (e) {
      _showSnackbar('Error adding category: $e');
    }
  }

  // Create Mock Test
  Future<void> _createMockTestPackage() async {
    if (_testTitleController.text.trim().isEmpty || _selectedCategory == null) {
      _showSnackbar('Please enter Title & Select Category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('mock_tests').add({
        'title': _testTitleController.text.trim(),
        'category': _selectedCategory,
        'testType': _selectedTestType,
        'durationMinutes': int.tryParse(_durationMinutesController.text.trim()) ?? 60,
        'totalMarks': int.tryParse(_totalMarksController.text.trim()) ?? 200,
        'isFree': _isFreeTest,
        'pyqYear': _selectedTestType == 'PYQ' ? _pyqYearController.text.trim() : '',
        'pyqShift': _selectedTestType == 'PYQ' ? _pyqShiftController.text.trim() : '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Test Package Created!', isSuccess: true);

      setState(() {
        _selectedTestId = docRef.id;
        _selectedTab = 2; // Jump to JSON upload
      });

      _testTitleController.clear();
      _isFreeTest = false;
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Upload JSON Questions
  Future<void> _uploadQuestionsJson() async {
    if (_selectedTestId == null || _jsonInputController.text.trim().isEmpty) {
      _showSnackbar('Select Test & Paste JSON');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<dynamic> jsonList = jsonDecode(_jsonInputController.text.trim());
      final batch = FirebaseFirestore.instance.batch();

      for (var q in jsonList) {
        final docRef = FirebaseFirestore.instance
            .collection('mock_tests')
            .doc(_selectedTestId)
            .collection('questions')
            .doc();

        batch.set(docRef, {
          'questionNo': q['questionNo'] ?? 1,
          'section': q['section'] ?? 'General',
          'questionText': q['questionText'] ?? '',
          'imageUrl': q['imageUrl'] ?? '',
          'options': q['options'] ?? [],
          'correctIndex': q['correctIndex'] ?? 0,
          'solutionText': q['solutionText'] ?? 'Explanation coming soon.',
          'solutionImageUrl': q['solutionImageUrl'] ?? '',
        });
      }

      await batch.commit();
      _showSnackbar('${jsonList.length} Questions Uploaded Successfully!', isSuccess: true);
      _jsonInputController.clear();
    } catch (e) {
      _showSnackbar('JSON/Firebase Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: Text('Admin Control Panel', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabBtn('0. Categories', 0),
                _buildTabBtn('1. Create Test', 1),
                _buildTabBtn('2. JSON Questions', 2),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTabContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final isSel = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSel ? const Color(0xFF1A237E) : Colors.transparent, width: 3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF1A237E) : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Exam Category', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _newCategoryController,
                decoration: const InputDecoration(labelText: 'Category Name (e.g. SSC, Railways, UP Police)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: _addCategory,
                child: const Text('ADD CATEGORY', style: TextStyle(color: Colors.white)),
              ),
              const Divider(height: 30),
              Text('Existing Categories:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('exam_categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Text('No categories added yet.');
                  return Wrap(
                    spacing: 8,
                    children: docs.map((d) => Chip(label: Text(d.id))).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (_selectedTab == 1) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Mock Test Package', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('exam_categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('Select Exam Category'),
                    items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.id))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _testTitleController,
                decoration: const InputDecoration(labelText: 'Test Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationMinutesController,
                      decoration: const InputDecoration(labelText: 'Duration (Mins)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _totalMarksController,
                      decoration: const InputDecoration(labelText: 'Total Marks', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Is Free Demo Test?'),
                value: _isFreeTest,
                onChanged: (val) => setState(() => _isFreeTest = val),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: _createMockTestPackage,
                child: const Text('CREATE TEST PACKAGE', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedTestId,
                    hint: const Text('Select Target Test'),
                    items: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return DropdownMenuItem(value: d.id, child: Text('${data['title']} (${data['category']})'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTestId = val),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonInputController,
                maxLines: 10,
                decoration: const InputDecoration(hintText: 'Paste JSON Questions Array Here...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                onPressed: _uploadQuestionsJson,
                child: const Text('UPLOAD QUESTIONS VIA JSON', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
  }
}
