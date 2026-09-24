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

  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _testTitleController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '60');
  final TextEditingController _totalMarksController = TextEditingController(text: '200');
  final TextEditingController _totalQuestionsController = TextEditingController(text: '100');

  String? _selectedCategory = 'SSC';
  String _tabType = 'Mocks Tests';
  String _sectionType = 'Full Tests';
  bool _isFreeTest = false;

  final TextEditingController _jsonInputController = TextEditingController();
  String? _selectedTestId;

  void _showSnackbar(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isSuccess ? Colors.green : Colors.red),
    );
  }

  Future<void> _addCategory() async {
    final catName = _newCategoryController.text.trim().toUpperCase();
    if (catName.isEmpty) return;
    await FirebaseFirestore.instance.collection('exam_categories').doc(catName).set({'name': catName, 'createdAt': FieldValue.serverTimestamp()});
    _newCategoryController.clear();
    _showSnackbar('Category Added!', isSuccess: true);
  }

  Future<void> _createTestPackage() async {
    if (_testTitleController.text.trim().isEmpty || _selectedCategory == null) return;
    setState(() => _isLoading = true);
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('mock_tests').add({
        'title': _testTitleController.text.trim(),
        'category': _selectedCategory!.toUpperCase(),
        'subCategory': _subCategoryController.text.trim(),
        'tabType': _tabType,
        'sectionType': _sectionType,
        'durationMinutes': int.tryParse(_durationController.text.trim()) ?? 60,
        'totalMarks': int.tryParse(_totalMarksController.text.trim()) ?? 200,
        'totalQuestions': int.tryParse(_totalQuestionsController.text.trim()) ?? 100,
        'isFree': _isFreeTest,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showSnackbar('Package Created!', isSuccess: true);
      setState(() { _selectedTestId = docRef.id; _selectedTab = 3; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadQuestionsJson() async {
    if (_selectedTestId == null || _jsonInputController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final List<dynamic> jsonList = jsonDecode(_jsonInputController.text.trim());
      final batch = FirebaseFirestore.instance.batch();
      for (var q in jsonList) {
        final docRef = FirebaseFirestore.instance.collection('mock_tests').doc(_selectedTestId).collection('questions').doc();
        batch.set(docRef, {
          'questionNo': q['questionNo'] ?? 1,
          'section': q['section'] ?? 'General',
          'questionText': q['questionText'] ?? '',
          'options': q['options'] ?? [],
          'correctIndex': q['correctIndex'] ?? 0,
          'solutionText': q['solutionText'] ?? '',
        });
      }
      await batch.commit();
      _showSnackbar('${jsonList.length} Questions Uploaded!', isSuccess: true);
      _jsonInputController.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1A237E), title: Text('Admin Control Panel', style: GoogleFonts.poppins(color: Colors.white))),
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
                  _buildTabBtn('1. Create Package', 1),
                  _buildTabBtn('3. JSON Batch', 3),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildTabContent()),
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
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSel ? const Color(0xFF1A237E) : Colors.transparent, width: 3))),
        child: Text(label, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF1A237E) : Colors.grey)),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _newCategoryController, decoration: const InputDecoration(labelText: 'New Category Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _addCategory, child: const Text('Add Category')),
            ],
          ),
        ),
      );
    } else if (_selectedTab == 1) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('exam_categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.id))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: _subCategoryController, decoration: const InputDecoration(labelText: 'Sub Category (Package)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tabType,
                items: const [DropdownMenuItem(value: 'Mocks Tests', child: Text('Mocks Tests')), DropdownMenuItem(value: 'Previous Years', child: Text('Previous Years'))],
                onChanged: (val) => setState(() => _tabType = val!),
                decoration: const InputDecoration(labelText: 'Tab Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _sectionType,
                items: const [DropdownMenuItem(value: 'Full Tests', child: Text('Full Tests')), DropdownMenuItem(value: 'Sectional Tests', child: Text('Sectional Tests'))],
                onChanged: (val) => setState(() => _sectionType = val!),
                decoration: const InputDecoration(labelText: 'Section Filter', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(controller: _testTitleController, decoration: const InputDecoration(labelText: 'Test Title', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _totalQuestionsController, decoration: const InputDecoration(labelText: 'Questions', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Mins', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _totalMarksController, decoration: const InputDecoration(labelText: 'Marks', border: OutlineInputBorder()))),
                ],
              ),
              SwitchListTile(title: const Text('Is Free?'), value: _isFreeTest, onChanged: (v) => setState(() => _isFreeTest = v)),
              ElevatedButton(onPressed: _createTestPackage, child: const Text('Create Package')),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: _selectedTestId,
                    hint: const Text('Select Target Test'),
                    items: snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data() as Map)['title'] ?? d.id))).toList(),
                    onChanged: (val) => setState(() => _selectedTestId = val),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: _jsonInputController, maxLines: 10, decoration: const InputDecoration(hintText: 'Paste Questions JSON Here...', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _uploadQuestionsJson, child: const Text('Upload JSON Batch')),
            ],
          ),
        ),
      );
    }
  }
}
