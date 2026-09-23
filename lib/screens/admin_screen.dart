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

  // Category Controllers
  final TextEditingController _newCategoryController = TextEditingController();

  // Test Creation Controllers
  final TextEditingController _testTitleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '60');
  final TextEditingController _totalMarksController = TextEditingController(text: '200');

  String? _selectedCategory = 'SSC';
  String _selectedSubCategory = 'SSC CGL 2026 - Tier 1';
  String _testType = 'Mocks Tests'; // Mocks Tests or Previous Years
  bool _isFreeTest = false;

  final List<String> _subCategories = [
    'SSC CGL 2026 - Tier 1',
    'SSC CPO 2026 - Tier 1',
    'SSC CPO 2025 - Tier 2',
    'SSC CHSL 2026 - Tier 1',
    'SSC CGL 2026 - Tier 2',
    'SSC GD Constable 2026',
    'SSC MTS 2026',
  ];

  // Single Question Controllers
  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _opt1Controller = TextEditingController();
  final TextEditingController _opt2Controller = TextEditingController();
  final TextEditingController _opt3Controller = TextEditingController();
  final TextEditingController _opt4Controller = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  int _correctOptIndex = 0;
  String _selectedSection = 'PART-B (General Intelligence)';

  final List<String> _sections = [
    'PART-A (General Awareness)',
    'PART-B (General Intelligence)',
    'PART-C (Quantitative Aptitude)',
    'PART-D (English Language)',
  ];

  // JSON Upload Controllers
  final TextEditingController _jsonInputController = TextEditingController();
  String? _selectedTestId;

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  // 1. Add Category
  Future<void> _addCategory() async {
    final catName = _newCategoryController.text.trim();
    if (catName.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('exam_categories').doc(catName).set({
        'name': catName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _newCategoryController.clear();
      _showSnackbar('Category "$catName" Added Successfully!', isSuccess: true);
    } catch (e) {
      _showSnackbar('Error adding category: $e');
    }
  }

  // 2. Create Test Package
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
        'subCategory': _selectedSubCategory,
        'testType': _testType,
        'durationMinutes': int.tryParse(_durationController.text.trim()) ?? 60,
        'totalMarks': int.tryParse(_totalMarksController.text.trim()) ?? 200,
        'isFree': _isFreeTest,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Test Package Created Successfully!', isSuccess: true);

      setState(() {
        _selectedTestId = docRef.id;
        _selectedTab = 2; // Jump to Question Add tab
      });

      _testTitleController.clear();
      _isFreeTest = false;
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Add Single Question
  Future<void> _addSingleQuestionManually() async {
    if (_selectedTestId == null) {
      _showSnackbar('Select Target Test First');
      return;
    }

    if (_questionTextController.text.trim().isEmpty ||
        _opt1Controller.text.trim().isEmpty ||
        _opt2Controller.text.trim().isEmpty) {
      _showSnackbar('Enter Question Text & At least 2 Options');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final qSnapshot = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(_selectedTestId)
          .collection('questions')
          .get();

      int nextQNo = qSnapshot.docs.length + 1;

      await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(_selectedTestId)
          .collection('questions')
          .add({
        'questionNo': nextQNo,
        'section': _selectedSection,
        'questionText': _questionTextController.text.trim(),
        'options': [
          _opt1Controller.text.trim(),
          _opt2Controller.text.trim(),
          _opt3Controller.text.trim(),
          _opt4Controller.text.trim(),
        ],
        'correctIndex': _correctOptIndex,
        'solutionText': _solutionController.text.trim().isEmpty
            ? 'Detailed explanation coming soon.'
            : _solutionController.text.trim(),
      });

      _showSnackbar('Question #$nextQNo Added Successfully!', isSuccess: true);

      _questionTextController.clear();
      _opt1Controller.clear();
      _opt2Controller.clear();
      _opt3Controller.clear();
      _opt4Controller.clear();
      _solutionController.clear();
    } catch (e) {
      _showSnackbar('Error adding question: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. Batch JSON Upload
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
          'section': q['section'] ?? 'PART-B (General Intelligence)',
          'questionText': q['questionText'] ?? '',
          'options': q['options'] ?? [],
          'correctIndex': q['correctIndex'] ?? 0,
          'solutionText': q['solutionText'] ?? 'Detailed explanation coming soon.',
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
        title: Text('Admin Control Panel', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabBtn('0. Categories', 0),
                  _buildTabBtn('1. Create Test', 1),
                  _buildTabBtn('2. Single Question', 2),
                  _buildTabBtn('3. JSON Batch', 3),
                ],
              ),
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
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSel ? const Color(0xFF1A237E) : Colors.transparent, width: 3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? const Color(0xFF1A237E) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Exam Category', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _newCategoryController,
                decoration: const InputDecoration(labelText: 'Category Name (e.g. SSC, Railways, Banking)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: _addCategory,
                child: const Text('ADD CATEGORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Mock Test Package', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('exam_categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('Select Main Category'),
                    items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.id))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    decoration: const InputDecoration(labelText: 'Main Exam Category', border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                items: _subCategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubCategory = val);
                },
                decoration: const InputDecoration(labelText: 'Sub-Exam Package Tier', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _testType,
                items: const [
                  DropdownMenuItem(value: 'Mocks Tests', child: Text('Mocks Tests')),
                  DropdownMenuItem(value: 'Previous Years', child: Text('Previous Years (PYQ)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _testType = val);
                },
                decoration: const InputDecoration(labelText: 'Test Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _testTitleController,
                decoration: const InputDecoration(labelText: 'Test Title (e.g. SSC CGL Tier I 2026 - Free Mock Test)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationController,
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
                child: const Text('CREATE TEST PACKAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedTab == 2) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manual Question Form', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _buildTestSelectorDropdown(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSection,
                items: _sections.map((sec) => DropdownMenuItem(value: sec, child: Text(sec))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSection = val);
                },
                decoration: const InputDecoration(labelText: 'Subject / Section', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _questionTextController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(controller: _opt1Controller, decoration: const InputDecoration(labelText: 'Option 1', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _opt2Controller, decoration: const InputDecoration(labelText: 'Option 2', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _opt3Controller, decoration: const InputDecoration(labelText: 'Option 3', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _opt4Controller, decoration: const InputDecoration(labelText: 'Option 4', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _correctOptIndex,
                decoration: const InputDecoration(labelText: 'Correct Option', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Option 1 is Correct')),
                  DropdownMenuItem(value: 1, child: Text('Option 2 is Correct')),
                  DropdownMenuItem(value: 2, child: Text('Option 3 is Correct')),
                  DropdownMenuItem(value: 3, child: Text('Option 4 is Correct')),
                ],
                onChanged: (val) => setState(() => _correctOptIndex = val ?? 0),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _solutionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Detailed Explanation / Solution', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: _addSingleQuestionManually,
                child: const Text('ADD QUESTION TO TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTestSelectorDropdown(),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonInputController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Paste Questions JSON Array Here...\n[\n  {\n    "questionNo": 1,\n    "section": "PART-B (General Intelligence)",\n    "questionText": "Question here...",\n    "options": ["A", "B", "C", "D"],\n    "correctIndex": 0,\n    "solutionText": "Explanation here..."\n  }\n]',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                onPressed: _uploadQuestionsJson,
                child: const Text('UPLOAD QUESTIONS VIA JSON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTestSelectorDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedTestId,
          hint: const Text('Select Target Test Package'),
          items: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: d.id,
              child: Text('${data['title']} (${data['subCategory'] ?? data['category']})'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedTestId = val),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
      },
    );
  }
}
