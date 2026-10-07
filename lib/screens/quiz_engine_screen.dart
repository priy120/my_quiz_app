import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'analysis_screen.dart';
import 'group_study_screen.dart';
import '../services/group_service.dart';

enum QuestionStatus { notVisited, notAnswered, answered, markedForReview, markedAndAnswered }

class MathJaxView extends StatefulWidget {
  final String content;
  final double fontSize;

  const MathJaxView({super.key, required this.content, this.fontSize = 14});

  @override
  State<MathJaxView> createState() => _MathJaxViewState();
}

class _MathJaxViewState extends State<MathJaxView> with AutomaticKeepAliveClientMixin {
  late WebViewController _controller;
  double _contentHeight = 80.0;
  bool _isReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'HeightChannel',
        onMessageReceived: (JavaScriptMessage message) {
          double? parsedHeight = double.tryParse(message.message);
          if (parsedHeight != null && parsedHeight > 0) {
            if (mounted) {
              setState(() {
                _contentHeight = parsedHeight + 6;
                _isReady = true;
              });
            }
          }
        },
      )
      ..loadHtmlString(_buildHtml(widget.content, widget.fontSize));
  }

  @override
  void didUpdateWidget(covariant MathJaxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      setState(() {
        _isReady = false;
      });
      _controller.loadHtmlString(_buildHtml(widget.content, widget.fontSize));
    }
  }

  String _buildHtml(String content, double size) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600;700&display=swap" rel="stylesheet">
      <script>
        MathJax = {
          tex: {
            inlineMath: [['\$', '\$'], ['\\\\(', '\\\\)']],
            displayMath: [['\$\$', '\$\$'], ['\\[', '\\]']]
          },
          chtml: { scale: 0.95 },
          svg: { scale: 0.95, fontCache: 'global' },
          startup: {
            pageReady: () => {
              return MathJax.startup.defaultPageReady().then(() => {
                setTimeout(sendHeight, 30);
              });
            }
          }
        };

        function sendHeight() {
          if (window.HeightChannel) {
            var body = document.body;
            var html = document.documentElement;
            var height = Math.max(
              body.scrollHeight, body.offsetHeight, 
              html.clientHeight, html.scrollHeight, html.offsetHeight
            );
            window.HeightChannel.postMessage(height.toString());
          }
        }
      </script>
      <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
      <style>
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          background-color: transparent !important;
          overflow: hidden !important;
        }
        body {
          font-family: 'Poppins', sans-serif !important;
          font-size: ${size}px !important;
          font-weight: 600 !important;
          color: #000000 !important;
          user-select: none;
          word-wrap: break-word;
          overflow-wrap: break-word;
          -webkit-font-smoothing: antialiased;
        }
        img { max-width: 100%; height: auto; }
        .mjx-chtml, .MathJax, mtd, mtr, span {
          color: #000000 !important;
          font-weight: 600 !important;
        }
      </style>
    </head>
    <body>$content</body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      constraints: const BoxConstraints(minHeight: 50.0),
      height: _contentHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isReady ? 1.0 : 0.0,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

class QuizEngineScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final bool isReattempt;
  final String? groupCode;

  const QuizEngineScreen({
    super.key,
    this.testId = 'default_test',
    this.testTitle = 'CompeteMe Live Mock Test',
    this.isReattempt = false,
    this.groupCode,
  });

  @override
  State<QuizEngineScreen> createState() => _QuizEngineScreenState();
}

class _QuizEngineScreenState extends State<QuizEngineScreen> {
  late PageController _pageController;
  int currentQuestionIndex = 0;
  
  Timer? _masterTimer;
  Timer? _sectionTimer;
  Timer? _questionTimer;

  final ValueNotifier<int> _secondsRemainingNotifier = ValueNotifier<int>(3600);
  int _currentQuestionSeconds = 0;
  late List<int> questionTimesInSeconds;

  bool _hasSectionalTiming = false;
  Map<String, int> _sectionDurationsInSeconds = {};
  int _currentSectionSecondsRemaining = 0;

  List<Map<String, dynamic>> questions = [];
  bool _isLoadingQuestions = true;
  late List<int?> selectedAnswers;
  late List<QuestionStatus> questionStatuses;
  String _currentLang = 'HI';

  List<String> _sections = ['All Sections'];
  int _currentSectionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _checkInternetAndFetch();

    UnityAds.load(
      placementId: 'BP_Interstitial_Android',
      onComplete: (placementId) => debugPrint('Quiz Interstitial Loaded: $placementId'),
      onFailed: (placementId, error, message) =>
          debugPrint('Quiz Interstitial Load Failed: $message'),
    );
  }

  Future<void> _checkInternetAndFetch() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Internet Connection Required'),
            content: const Text('Is test ko access karne ke liye active internet connection zaroori hai.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
      return;
    }
    
    _fetchQuestionsAndSavedState();
  }

  Future<void> _fetchQuestionsAndSavedState() async {
    try {
      final testDoc = await FirebaseFirestore.instance
          .collection('mock_tests')
          .doc(widget.testId)
          .get();

      int initialSeconds = 3600;
      if (testDoc.exists) {
        final testData = testDoc.data();
        int adminDurationMinutes = testData?['durationMinutes'] ?? 60;
        initialSeconds = adminDurationMinutes * 60;

        _hasSectionalTiming = testData?['hasSectionalTiming'] ?? false;
        if (_hasSectionalTiming && testData?['sectionTimings'] != null) {
          Map rawMap = testData!['sectionTimings'];
          rawMap.forEach((key, val) {
            _sectionDurationsInSeconds[key.toString()] = ((val as int?) ?? 15) * 60;
          });
        }
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('mock_tests')
            .doc(widget.testId)
            .collection('questions')
            .orderBy('questionNo', descending: false)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          snapshot = await FirebaseFirestore.instance
              .collection('mock_tests')
              .doc(widget.testId)
              .collection('questions')
              .orderBy('questionNo', descending: false)
              .get(const GetOptions(source: Source.server));
        }
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('mock_tests')
            .doc(widget.testId)
            .collection('questions')
            .orderBy('questionNo', descending: false)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        questions = snapshot.docs.map((doc) => doc.data()).toList();
        
        Set<String> secSet = {};
        for (var q in questions) {
          if (q['section'] != null && q['section'].toString().isNotEmpty) {
            secSet.add(q['section'].toString());
          }
        }
        if (secSet.isNotEmpty) {
          _sections = secSet.toList();
        }

        selectedAnswers = List<int?>.filled(questions.length, null);
        questionStatuses = List<QuestionStatus>.filled(questions.length, QuestionStatus.notVisited);
        questionTimesInSeconds = List<int>.filled(questions.length, 0);

        final user = FirebaseAuth.instance.currentUser;

        if (user != null && !widget.isReattempt) {
          final savedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('paused_tests')
              .doc(widget.testId)
              .get();

          if (savedDoc.exists) {
            final data = savedDoc.data()!;
            initialSeconds = data['remainingSeconds'] ?? initialSeconds;
            currentQuestionIndex = data['currentIndex'] ?? 0;
            List<dynamic> savedAnswers = data['selectedAnswers'] ?? [];
            List<dynamic> savedTimes = data['questionTimes'] ?? [];

            for (int i = 0; i < savedAnswers.length && i < selectedAnswers.length; i++) {
              if (savedAnswers[i] != null) {
                selectedAnswers[i] = savedAnswers[i];
                questionStatuses[i] = QuestionStatus.answered;
              }
            }
            for (int i = 0; i < savedTimes.length && i < questionTimesInSeconds.length; i++) {
              questionTimesInSeconds[i] = savedTimes[i] ?? 0;
            }
          }
        }

        _secondsRemainingNotifier.value = initialSeconds;

        if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
          questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
        }

        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentQuestionIndex);
        } else {
          _pageController = PageController(initialPage: currentQuestionIndex);
        }

        setState(() => _isLoadingQuestions = false);

        if (_hasSectionalTiming) {
          _startSectionTimer();
        } else {
          _startMasterTimer();
        }
        _startQuestionTimer();
      } else {
        setState(() => _isLoadingQuestions = false);
      }
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
    }
  }

  void _startMasterTimer() {
    _masterTimer?.cancel();
    _masterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemainingNotifier.value > 0) {
        _secondsRemainingNotifier.value--;
      } else {
        _masterTimer?.cancel();
        _questionTimer?.cancel();
        _submitTestWithAd();
      }
    });
  }

  void _startSectionTimer() {
    _sectionTimer?.cancel();
    String currentSec = _sections[_currentSectionIndex];
    _currentSectionSecondsRemaining = _sectionDurationsInSeconds[currentSec] ?? (15 * 60);
    _secondsRemainingNotifier.value = _currentSectionSecondsRemaining;

    _sectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSectionSecondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _currentSectionSecondsRemaining--;
            _secondsRemainingNotifier.value = _currentSectionSecondsRemaining;
          });
        }
      } else {
        timer.cancel();
        _handleSectionTimeOver();
      }
    });
  }

  void _handleSectionTimeOver() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Time over for ${_sections[_currentSectionIndex]}! Auto-switching section."),
        backgroundColor: Colors.redAccent,
      ),
    );

    if (_currentSectionIndex < _sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });

      String nextSec = _sections[_currentSectionIndex];
      int nextQIndex = questions.indexWhere((q) => q['section'] == nextSec);
      if (nextQIndex != -1) {
        _navigateToQuestion(nextQIndex, force: true);
      }
      _startSectionTimer();
    } else {
      _submitTestWithAd();
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    if (questions.isEmpty) return;
    _currentQuestionSeconds = questionTimesInSeconds[currentQuestionIndex];

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentQuestionSeconds++;
          questionTimesInSeconds[currentQuestionIndex] = _currentQuestionSeconds;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getParsedText(String rawText) {
    if (!rawText.contains('\n\n')) return rawText;
    final parts = rawText.split('\n\n');
    if (parts.length >= 2) {
      return _currentLang == 'HI' ? parts[1].trim() : parts[0].trim();
    }
    return rawText;
  }

  List<String> _extractOptions(dynamic rawOptions) {
    if (rawOptions is List) {
      return rawOptions.map((e) => _getParsedText(e.toString())).toList();
    } else if (rawOptions is Map) {
      return rawOptions.values.map((e) => _getParsedText(e.toString())).toList();
    }
    return ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  }

  Widget _buildMathOrText(String content, {double fontSize = 14}) {
    if (content.trim().isEmpty) return const SizedBox();
    return MathJaxView(content: content, fontSize: fontSize);
  }

  void _onQuestionPageChanged(int index) {
    if (_hasSectionalTiming) {
      String currentSec = _sections[_currentSectionIndex];
      String targetSec = questions[index]['section'] ?? currentSec;

      if (currentSec != targetSec) {
        _pageController.jumpToPage(currentQuestionIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Is section ke aage nahi ja sakte! Pehle is section ko submit karein."),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    questionTimesInSeconds[currentQuestionIndex] = _currentQuestionSeconds;

    setState(() {
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }
      currentQuestionIndex = index;
      if (questionStatuses[currentQuestionIndex] == QuestionStatus.notVisited) {
        questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
      }

      if (questions.isNotEmpty && questions[index]['section'] != null) {
        String sec = questions[index]['section'].toString();
        int secIdx = _sections.indexOf(sec);
        if (secIdx != -1) {
          _currentSectionIndex = secIdx;
        }
      }
    });

    _startQuestionTimer();
  }

  void _navigateToQuestion(int index, {bool force = false}) {
    if (!force && _hasSectionalTiming) {
      String currentSec = _sections[_currentSectionIndex];
      String targetSec = questions[index]['section'] ?? currentSec;

      if (currentSec != targetSec) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sectional lock active! Submit this section first."),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectOption(int optIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = optIndex;
    });
  }

  void _clearResponse() {
    setState(() {
      selectedAnswers[currentQuestionIndex] = null;
      questionStatuses[currentQuestionIndex] = QuestionStatus.notAnswered;
    });
  }

  void _markForReviewAndNext() {
    setState(() {
      questionStatuses[currentQuestionIndex] = selectedAnswers[currentQuestionIndex] != null
          ? QuestionStatus.markedAndAnswered
          : QuestionStatus.markedForReview;
      if (currentQuestionIndex < questions.length - 1) {
        _navigateToQuestion(currentQuestionIndex + 1);
      }
    });
  }

  void _saveAndNext() {
    setState(() {
      questionStatuses[currentQuestionIndex] = selectedAnswers[currentQuestionIndex] != null
          ? QuestionStatus.answered
          : QuestionStatus.notAnswered;
      if (currentQuestionIndex < questions.length - 1) {
        _navigateToQuestion(currentQuestionIndex + 1);
      }
    });
  }

  Future<bool> _showPauseDialog() async {
    questionTimesInSeconds[currentQuestionIndex] = _currentQuestionSeconds;

    bool? shouldPause = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('PAUSE TEST', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to pause & close this test? Progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('paused_tests')
                    .doc(widget.testId)
                    .set({
                  'testId': widget.testId,
                  'testTitle': widget.testTitle,
                  'remainingSeconds': _secondsRemainingNotifier.value,
                  'currentIndex': currentQuestionIndex,
                  'selectedAnswers': selectedAnswers,
                  'questionTimes': questionTimesInSeconds,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return shouldPause ?? false;
  }

  void _openQuestionPaletteSheet() {
    int answeredCount = questionStatuses.where((s) => s == QuestionStatus.answered).length;
    int markedCount = questionStatuses.where((s) => s == QuestionStatus.markedForReview).length;
    int notVisitedCount = questionStatuses.where((s) => s == QuestionStatus.notVisited).length;
    int markedAndAnsweredCount = questionStatuses.where((s) => s == QuestionStatus.markedAndAnswered).length;
    int notAnsweredCount = questionStatuses.where((s) => s == QuestionStatus.notAnswered).length;

    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 10),
                        Text(user?.displayName ?? 'Student', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildLegendBadge(Colors.green, '$answeredCount Answered'),
                        _buildLegendBadge(Colors.purple, '$markedCount Marked'),
                        _buildLegendBadge(Colors.grey.shade300, '$notVisitedCount Not Visited', textColor: Colors.black),
                        _buildLegendBadge(Colors.blue, '$markedAndAnsweredCount Marked & Answered'),
                        _buildLegendBadge(Colors.red, '$notAnsweredCount Not Answered'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('SECTION : ${_sections[_currentSectionIndex]}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Divider(),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final status = questionStatuses[index];
                        Color bgColor;
                        Color textColor = Colors.white;

                        switch (status) {
                          case QuestionStatus.answered:
                            bgColor = Colors.green;
                            break;
                          case QuestionStatus.markedForReview:
                            bgColor = Colors.purple;
                            break;
                          case QuestionStatus.markedAndAnswered:
                            bgColor = Colors.blue;
                            break;
                          case QuestionStatus.notAnswered:
                            bgColor = Colors.red;
                            break;
                          case QuestionStatus.notVisited:
                          default:
                            bgColor = Colors.grey.shade300;
                            textColor = Colors.black;
                            break;
                        }

                        return InkWell(
                          onTap: () {
                            if (_hasSectionalTiming) {
                              String qSec = questions[index]['section'] ?? '';
                              if (qSec != _sections[_currentSectionIndex]) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Section lock active!")),
                                );
                                return;
                              }
                            }
                            Navigator.pop(context);
                            _navigateToQuestion(index);
                          },
                          child: Container(
                            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmSubmitDialog(isSectionSubmit: true);
                        },
                        child: const Text('Submit This Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900, padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmSubmitDialog(isSectionSubmit: false);
                        },
                        child: const Text('Submit Full Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendBadge(Color color, String label, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmSubmitDialog({bool isSectionSubmit = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSectionSubmit ? 'CONFIRM SECTION SUBMIT' : 'CONFIRM TEST SUBMIT'),
        content: Text(isSectionSubmit ? 'Are you sure you want to submit this section?' : 'Are you sure you want to submit the entire test now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () {
              Navigator.pop(context);
              if (isSectionSubmit && _hasSectionalTiming) {
                _handleSectionTimeOver();
              } else {
                _submitTestWithAd();
              }
            },
            child: const Text('Yes, Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTestWithAd() async {
    questionTimesInSeconds[currentQuestionIndex] = _currentQuestionSeconds;
    setState(() => _isSubmitting = true);

    UnityAds.showVideoAd(
      placementId: 'BP_Interstitial_Android',
      onComplete: (placementId) => _processSubmitAndNavigate(),
      onFailed: (placementId, error, message) => _processSubmitAndNavigate(),
      onSkipped: (placementId) => _processSubmitAndNavigate(),
    );
  }

  Future<void> _processSubmitAndNavigate() async {
    _masterTimer?.cancel();
    _sectionTimer?.cancel();
    _questionTimer?.cancel();

    int correctCount = 0;
    int wrongCount = 0;
    int unattemptedCount = 0;

    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == null) {
        unattemptedCount++;
      } else if (selectedAnswers[i] == questions[i]['correctIndex']) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    double totalScore = (correctCount * 2) - (wrongCount * 0.5);
    if (totalScore < 0) totalScore = 0;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('test_attempts')
          .doc(widget.testId)
          .get();

      int newAttemptCount = 1;
      if (existingDoc.exists) {
        int currentAttempts = existingDoc.data()?['attemptCount'] ?? 1;
        newAttemptCount = currentAttempts + 1;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('test_attempts')
          .doc(widget.testId)
          .set({
        'testId': widget.testId,
        'testTitle': widget.testTitle,
        'score': totalScore,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'selectedAnswers': selectedAnswers,
        'questionTimes': questionTimesInSeconds,
        'attemptCount': newAttemptCount,
        'status': 'Completed',
        'attemptedAt': FieldValue.serverTimestamp(),
      });

      if (!widget.isReattempt) {
        String? activeGroup = widget.groupCode ?? GroupStudyScreen.activeGroupCode;
        if (activeGroup != null && activeGroup.isNotEmpty) {
          try {
            await GroupService().updateGroupScore(
              activeGroup, 
              totalScore, 
              isReattempt: widget.isReattempt,
            );
          } catch (e) {
            debugPrint('Error updating group score: $e');
          }
        }
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('paused_tests')
            .doc(widget.testId)
            .delete();
      } catch (e) {
        debugPrint('Error removing paused test: $e');
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(
            testId: widget.testId,
            testTitle: widget.testTitle,
            score: totalScore,
            totalQuestions: questions.length,
            correctCount: correctCount,
            wrongCount: wrongCount,
            unattemptedCount: unattemptedCount,
            questionTimes: questionTimesInSeconds,
            groupCode: widget.groupCode ?? GroupStudyScreen.activeGroupCode,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _masterTimer?.cancel();
    _sectionTimer?.cancel();
    _questionTimer?.cancel();
    _secondsRemainingNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.testTitle), backgroundColor: const Color(0xFF1A237E)),
        body: const Center(child: Text("No questions uploaded in this test yet.")),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldExit = await _showPauseDialog();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(widget.testTitle, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.g_translate, color: Colors.white, size: 20),
              onSelected: (val) => setState(() => _currentLang = val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'EN', child: Text('English')),
                const PopupMenuItem(value: 'HI', child: Text('Hindi')),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
              child: ValueListenableBuilder<int>(
                valueListenable: _secondsRemainingNotifier,
                builder: (context, seconds, child) {
                  return Text(
                    _formatTime(seconds),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
            IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: () {}),
          ],
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50.0),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.green.shade700,
            onPressed: _openQuestionPaletteSheet,
            child: const Icon(Icons.grid_view, color: Colors.white),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: const Color(0xFF1A237E),
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final isSel = _currentSectionIndex == index;
                      return GestureDetector(
                        onTap: () {
                          if (_hasSectionalTiming && index != _currentSectionIndex) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sectional lock active! Wait for timer or submit current section."),
                                backgroundColor: Colors.black87,
                              ),
                            );
                          } else if (!_hasSectionalTiming) {
                            String targetSec = _sections[index];
                            int qIdx = questions.indexWhere((q) => q['section'] == targetSec);
                            if (qIdx != -1) _navigateToQuestion(qIdx);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.indigo.shade900 : Colors.transparent,
                            border: Border(bottom: BorderSide(color: isSel ? Colors.amber : Colors.transparent, width: 3)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Text(
                                _sections[index],
                                style: TextStyle(
                                  color: isSel ? Colors.amber : Colors.white70,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              if (_hasSectionalTiming && !isSel)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0),
                                  child: Icon(Icons.lock, size: 12, color: Colors.amber),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    onPageChanged: _onQuestionPageChanged,
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final qData = questions[index];
                      final String displayQText = _getParsedText(qData['questionText'] ?? '');
                      final List<String> displayOptions = _extractOptions(qData['options']);
                      final String? qImageUrl = qData['imageUrl'] ?? qData['image'];
                      final List<dynamic>? optImages = qData['optionImages'];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('No. ${index + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF1A237E), width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF1A237E)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatTime(_currentQuestionSeconds),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1A237E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.bookmark_border, size: 20), onPressed: () {}),
                                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildMathOrText(displayQText, fontSize: 14),
                                    if (qImageUrl != null && qImageUrl.toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 250),
                                        width: double.infinity,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            qImageUrl.toString().trim(),
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: List.generate(displayOptions.length, (optIdx) {
                                final isSelected = selectedAnswers[index] == optIdx;
                                String? optImg;
                                if (optImages != null && optIdx < optImages.length && optImages[optIdx] != null) {
                                  optImg = optImages[optIdx].toString();
                                }

                                return Card(
                                  elevation: isSelected ? 2 : 1,
                                  color: isSelected ? Colors.indigo.shade50 : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildMathOrText(displayOptions[optIdx], fontSize: 13),
                                        if (optImg != null && optImg.trim().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              optImg.trim(),
                                              height: 90,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => const SizedBox(),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                    leading: Radio<int>(
                                      value: optIdx,
                                      groupValue: selectedAnswers[index],
                                      activeColor: const Color(0xFF1A237E),
                                      onChanged: (val) => _selectOption(optIdx),
                                    ),
                                    onTap: () => _selectOption(optIdx),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: currentQuestionIndex > 0 ? () => _navigateToQuestion(currentQuestionIndex - 1) : null,
                          child: const Text('Previous Question', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purple), padding: EdgeInsets.zero),
                          onPressed: _markForReviewAndNext,
                          child: const Text('Mark & Save For Review', style: TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: EdgeInsets.zero),
                          onPressed: _clearResponse,
                          child: const Text('Clear Response', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), padding: EdgeInsets.zero),
                          onPressed: _saveAndNext,
                          child: const Text('Save & Next', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        "Submitting Test & Loading Analysis...",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
