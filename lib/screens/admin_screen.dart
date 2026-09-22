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

  // Controllers for Mock Test Creation
  final TextEditingController _testTitleController = TextEditingController();
  final TextEditingController _durationMinutesController = TextEditingController(text: '60');
  final TextEditingController _totalMarksController = TextEditingController(text: '200');
  final TextEditingController _pyqYearController = TextEditingController(text: '2025');
  final TextEditingController _pyqShiftController = TextEditingController(text: 'Shift 1');

  String _selectedCategory = 'SSC CGL';
  String _selectedTestType = 'Full Mock'; // Full Mock, PYQ, Sectional
  bool _isFreeTest = false;

  final List<String> _categories = [
    'SSC CGL',
    'SSC CPO',
    'SSC CHSL',
    'SSC MTS',
    'SSC GD',
    'Railways',
    'UP Police',
    'Banking',
    'GK Booster',
    'Maths Booster',
    'English Booster',
  ];

  final List<String> _testTypes = [
    'Full Mock',
    'PYQ',
    'Sectional',
  ];

  // Controllers for JSON Questions Upload
  final TextEditingController _jsonInputController = TextEditingController();
  String? _selectedTestId;

  // Controllers for PDF Upload
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

  // 1. Create Advanced Test Package
  Future<void> _createMockTestPackage() async {
    if (_testTitleController.text.trim().isEmpty) {
      _showSnackbar('Please enter Test Title');
      return;
    }

    setState(() => _isLoading = true);

    try {
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('mock_tests').add({
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

      _showSnackbar('Test Package Created! Auto-selected for JSON upload.', isSuccess: true);

      setState(() {
        _selectedTestId = docRef.id;
        _selectedTab = 1;
      });

      _testTitleController.clear();
      _isFreeTest = false;
    } catch (e) {
      _showSnackbar('Error creating test: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Upload JSON Questions & Explanations Array
  Future<void> _uploadQuestionsJson() async {
    if (_selectedTestId == null || _selectedTestId!.isEmpty) {
      _showSnackbar('Please select a Mock Test Package first');
      return;
    }

    if (_jsonInputController.text.trim().isEmpty) {
      _showSnackbar('Please paste valid JSON questions array');
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
          'questionText': q['questionText'] ?? q['questionText_en'] ?? '',
          'imageUrl': q['imageUrl'] ?? '',
          'options': q['options'] ?? q['options_en'] ?? [],
          'correctIndex': q['correctIndex'] ?? 0,
          'solutionText': q['solutionText'] ?? q['solutionText_en'] ?? 'Detailed explanation coming soon.',
          'solutionImageUrl': q['solutionImageUrl'] ?? '',
        });
      }

      await batch.commit();
      _showSnackbar('All ${jsonList.length} Questions & Solutions Uploaded Successfully!', isSuccess: true);
      _jsonInputController.clear();
    } catch (e) {
      _showSnackbar('Invalid JSON Format or Firebase Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Upload PDF Study Material
  Future<void> _uploadPdfNotes() async {
    if (_pdfTitleController.text.trim().isEmpty || _pdfUrlController.text.trim().isEmpty) {
      _showSnackbar('Please enter PDF Title and valid Public URL');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pdfs').add({
        'title': _pdfTitleController.text.trim(),
        'category': _pdfCategoryController.text.trim().isEmpty ? _selectedCategory : _pdfCategoryController.text.trim(),
        'size': _pdfSizeController.text.trim().isEmpty ? '2.5 MB' : _pdfSizeController.text.trim(),
        'url': _pdfUrlController.text.trim(),
        'date': '2026',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('PDF Study Material Uploaded Successfully!', isSuccess: true);
      _pdfTitleController.clear();
      _pdfCategoryController.clear();
      _pdfSizeController.clear();
      _pdfUrlController.clear();
    } catch (e) {
      _showSnackbar('Error publishing PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: Text(
          'CompeteMe Admin Portal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // Navigation Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabButton('1. Create Test', 0),
                _buildTabButton('2. JSON Questions', 1),
                _buildTabButton('3. Upload PDF', 2),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSelectedTabContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1A237E) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildCreateTestTab();
      case 1:
        return _buildJsonUploadTab();
      case 2:
        return _buildPdfUploadTab();
      default:
        return const SizedBox();
    }
  }

  // Tab 1 UI: Create Test
  Widget _buildCreateTestTab() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Exam Test / PYQ / Sectional Series', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Exam Category', border: OutlineInputBorder()),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val ?? 'SSC CGL'),
            ),
            const SizedBox(height: 12),

            // Test Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedTestType,
              decoration: const InputDecoration(labelText: 'Test Type', border: OutlineInputBorder()),
              items: _testTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) => setState(() => _selectedTestType = val ?? 'Full Mock'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _testTitleController,
              decoration: const InputDecoration(
                labelText: 'Test Title (e.g. SSC CGL 2026 Tier 1 Full Mock 01)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedTestType == 'PYQ') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pyqYearController,
                      decoration: const InputDecoration(labelText: 'PYQ Year (e.g. 2025)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _pyqShiftController,
                      decoration: const InputDecoration(labelText: 'Shift Tag (e.g. Shift 1)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (Mins)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _totalMarksController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Marks', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Is Free Demo Test?'),
              subtitle: const Text('Yes = Free for all, No = Requires Pass'),
              value: _isFreeTest,
              activeColor: const Color(0xFF1A237E),
              onChanged: (val) => setState(() => _isFreeTest = val),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: _createMockTestPackage,
                child: const Text('CREATE PACKAGE & NEXT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 2 UI: JSON Upload
  Widget _buildJsonUploadTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('mock_tests').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: _selectedTestId,
                  hint: const Text('Select Target Test Package'),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('${data['title']} (${data['category']})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTestId = val),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Target Mock Test Package',
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paste JSON Questions & Solutions Array', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _jsonInputController,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: 'Paste JSON [...] Array Here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: _uploadQuestionsJson,
                    child: const Text('UPLOAD ALL QUESTIONS & SOLUTIONS VIA JSON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tab 3 UI: Upload PDF
  Widget _buildPdfUploadTab() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publish PDF Notes & Formula Sheets', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            TextField(
              controller: _pdfTitleController,
              decoration: const InputDecoration(
                labelText: 'PDF Title (e.g. UP Police GK Formula Sheet)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pdfCategoryController,
              decoration: const InputDecoration(
                labelText: 'Category (e.g. SSC CGL, Maths Notes, GK)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pdfSizeController,
              decoration: const InputDecoration(
                labelText: 'File Size (e.g. 3.2 MB)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pdfUrlController,
              decoration: const InputDecoration(
                labelText: 'Google Drive / Storage Public Link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: _uploadPdfNotes,
                child: const Text('PUBLISH PDF NOTES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
