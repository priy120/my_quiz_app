import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MathJaxView extends StatefulWidget {
  final String content;
  final double fontSize;

  const MathJaxView({super.key, required this.content, this.fontSize = 13});

  @override
  State<MathJaxView> createState() => _MathJaxViewState();
}

class _MathJaxViewState extends State<MathJaxView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_buildHtml(widget.content, widget.fontSize));
  }

  @override
  void didUpdateWidget(covariant MathJaxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.loadHtmlString(_buildHtml(widget.content, widget.fontSize));
    }
  }

  String _buildHtml(String content, double size) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <script>
        MathJax = {
          tex: {
            inlineMath: [['\$', '\$'], ['\\\\(', '\\\\)']],
            displayMath: [['\$\$', '\$\$'], ['\\[', '\\]']]
          },
          svg: { fontCache: 'global' }
        };
      </script>
      <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
      <style>
        body {
          font-family: 'Poppins', sans-serif;
          font-size: ${size}px;
          color: #212121;
          margin: 0;
          padding: 0;
          background-color: transparent;
          user-select: none;
        }
      </style>
    </head>
    <body>
      $content
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.fontSize * 4.0,
      child: WebViewWidget(controller: _controller),
    );
  }
}

class SolutionsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const SolutionsScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isReattemptMode = false;
  
  Map<int, int?> _userReattemptAnswers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _extractOptions(dynamic rawOptions) {
    if (rawOptions is List) {
      return rawOptions.map((e) => e.toString()).toList();
    } else if (rawOptions is Map) {
      return rawOptions.values.map((e) => e.toString()).toList();
    }
    return ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  }

  Widget _buildMathOrText(String content, {double fontSize = 13}) {
    if (content.trim().isEmpty) return const SizedBox();
    return MathJaxView(content: content, fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.testTitle} - Solutions',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('test_attempts').doc(widget.testId).snapshots()
            : null,
        builder: (context, attemptSnapshot) {
          List<dynamic> savedUserAnswers = [];
          if (attemptSnapshot.hasData && attemptSnapshot.data!.exists) {
            final attemptData = attemptSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            savedUserAnswers = attemptData['selectedAnswers'] ?? [];
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('mock_tests').doc(widget.testId).collection('questions').orderBy('questionNo').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final questions = snapshot.data!.docs;
              if (questions.isEmpty) return const Center(child: Text('No solutions available for this test.'));

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, color: Color(0xFF1A237E), size: 20),
                        const SizedBox(width: 8),
                        Text('Re-attempt Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        const Spacer(),
                        Switch(
                          value: _isReattemptMode,
                          activeColor: const Color(0xFF1A237E),
                          onChanged: (val) {
                            setState(() {
                              _isReattemptMode = val;
                              if (!_isReattemptMode) _userReattemptAnswers.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => _currentIndex = idx),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final qData = questions[index].data() as Map<String, dynamic>;
                        final String qText = qData['questionText'] ?? '';
                        final String? qImageUrl = qData['imageUrl'];
                        final List<dynamic>? optImages = qData['optionImages'];
                        final List<String> options = _extractOptions(qData['options']);
                        final int correctIdx = qData['correctIndex'] ?? 0;
                        final String solution = qData['solutionText'] ?? 'Detailed explanation coming soon.';

                        int? userSelectedIdx = (index < savedUserAnswers.length) ? savedUserAnswers[index] : null;
                        
                        if (_isReattemptMode && _userReattemptAnswers.containsKey(index)) {
                          userSelectedIdx = _userReattemptAnswers[index];
                        }

                        bool isAttempted = userSelectedIdx != null;
                        bool isUserCorrect = isAttempted && (userSelectedIdx == correctIdx);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Question ${index + 1} of ${questions.length}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1A237E)),
                                  ),
                                  if (!_isReattemptMode)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: !isAttempted
                                            ? Colors.grey.shade200
                                            : (isUserCorrect ? Colors.green.shade100 : Colors.red.shade100),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        !isAttempted
                                            ? 'UNATTEMPTED'
                                            : (isUserCorrect ? 'CORRECT' : 'INCORRECT'),
                                        style: TextStyle(
                                          color: !isAttempted
                                              ? Colors.grey.shade700
                                              : (isUserCorrect ? Colors.green.shade800 : Colors.red.shade800),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildMathOrText(qText, fontSize: 13),
                                      if (qImageUrl != null && qImageUrl.trim().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(qImageUrl.trim(), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              ...List.generate(options.length, (optIdx) {
                                final isCorrectOpt = optIdx == correctIdx;
                                final isUserSelectedOpt = optIdx == userSelectedIdx;

                                String? optImg;
                                if (optImages != null && optIdx < optImages.length && optImages[optIdx] != null) {
                                  optImg = optImages[optIdx].toString();
                                }

                                Color cardColor = Colors.white;
                                BorderSide border = BorderSide(color: Colors.grey.shade300);
                                Widget leadingIcon = const Icon(Icons.circle_outlined, size: 16, color: Colors.grey);

                                if (!_isReattemptMode) {
                                  if (isCorrectOpt) {
                                    cardColor = Colors.green.shade50;
                                    border = const BorderSide(color: Colors.green, width: 2);
                                    leadingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
                                  } else if (isUserSelectedOpt && !isUserCorrect) {
                                    cardColor = Colors.red.shade50;
                                    border = const BorderSide(color: Colors.red, width: 2);
                                    leadingIcon = const Icon(Icons.cancel, color: Colors.red, size: 18);
                                  }
                                } else {
                                  if (isUserSelectedOpt) {
                                    cardColor = Colors.indigo.shade50;
                                    border = const BorderSide(color: Color(0xFF1A237E), width: 2);
                                    leadingIcon = const Icon(Icons.radio_button_checked, color: Color(0xFF1A237E), size: 18);
                                  }
                                }

                                return Card(
                                  elevation: isUserSelectedOpt ? 2 : 1,
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(8)),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    onTap: _isReattemptMode
                                        ? () {
                                            setState(() {
                                              _userReattemptAnswers[index] = optIdx;
                                            });
                                          }
                                        : null,
                                    leading: leadingIcon,
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildMathOrText(options[optIdx], fontSize: 12),
                                        if (optImg != null && optImg.trim().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Image.network(optImg.trim(), height: 80, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
                                        ]
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 14),

                              if (!_isReattemptMode)
                                Card(
                                  color: Colors.amber.shade50,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.amber.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                                            const SizedBox(width: 6),
                                            Text('Explanation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.brown.shade800, fontSize: 13)),
                                          ],
                                        ),
                                        const Divider(),
                                        _buildMathOrText(solution, fontSize: 12),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                          onPressed: _currentIndex > 0
                              ? () => _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                              : null,
                          icon: const Icon(Icons.arrow_back_ios, size: 12, color: Colors.black87),
                          label: const Text('Previous', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Text('${_currentIndex + 1} / ${questions.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                          onPressed: _currentIndex < questions.length - 1
                              ? () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                              : null,
                          icon: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                          label: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
