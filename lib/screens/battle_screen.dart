import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/battle_service.dart';
import 'battle_analysis_screen.dart';

class BattleScreen extends StatefulWidget {
  final String testTitle;
  final List<Map<String, dynamic>> questions;

  const BattleScreen({
    super.key,
    required this.testTitle,
    required this.questions,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final BattleService _battleService = BattleService();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? roomId;
  bool isSearching = true;
  bool isBotMatch = false;

  int currentQuestionIndex = 0;
  int myScore = 0;
  int streakCount = 0;
  int? selectedOption;

  // Track user answers for final analysis review (-1 for time out)
  List<int?> myAnswers = [];

  // Per-Question Countdown Timer
  Timer? _qTimer;
  int _secondsLeft = 10;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  void _startTimer() {
    _qTimer?.cancel();
    setState(() => _secondsLeft = 10);

    _qTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (selectedOption != null) return;

    setState(() {
      streakCount = 0;
      selectedOption = -1;
      myAnswers.add(-1); // Record timeout/unattempted
    });

    _nextQuestionWithDelay();
  }

  Future<void> _startMatchmaking() async {
    String? rId = await _battleService.findOrMatchOpponent(
        widget.testTitle, widget.questions);
    if (mounted) setState(() => roomId = rId);

    // 8 Seconds Timeout -> AI Bot Fallback
    Future.delayed(const Duration(seconds: 8), () async {
      if (isSearching && mounted) {
        await _battleService.cancelSearch();
        String botRoomId = await _battleService.createBotRoom(
            widget.testTitle, widget.questions);
        _battleService.startBotSimulation(botRoomId, widget.questions.length);

        if (mounted) {
          setState(() {
            roomId = botRoomId;
            isSearching = false;
            isBotMatch = true;
          });
          _startTimer();
        }
      }
    });
  }

  void _answerQuestion(int optIdx, int correctIdx) {
    if (selectedOption != null) return;
    _qTimer?.cancel();

    int pointsEarned = 0;
    if (optIdx == correctIdx) {
      streakCount++;
      pointsEarned = (streakCount >= 2) ? 3 : 2; // Combo Bonus Multiplier
    } else {
      streakCount = 0; // Reset streak on wrong answer
    }

    setState(() {
      selectedOption = optIdx;
      myAnswers.add(optIdx); // Record user choice
      myScore += pointsEarned;
    });

    bool isPlayer1 = true;
    _battleService.updateMyScore(
        roomId!, isPlayer1, myScore, currentQuestionIndex + 1);

    _nextQuestionWithDelay();
  }

  void _nextQuestionWithDelay() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedOption = null;
        });
        _startTimer();
      } else {
        _finishMatch();
      }
    });
  }

  void _finishMatch() async {
    _qTimer?.cancel();

    DataSnapshot snap =
        await FirebaseDatabase.instance.ref('battle_rooms/$roomId').get();
    int oppScore = 0;
    String oppName = "Opponent";

    if (snap.exists && snap.value != null) {
      Map data = snap.value as Map;
      Map p1 = data['player1'] ?? {};
      Map p2 = data['player2'] ?? {};
      bool isP1 = p1['uid'] == currentUid;
      Map oppData = isP1 ? p2 : p1;

      oppScore = (oppData['score'] ?? 0);
      oppName = (oppData['name'] ?? 'Opponent');
    }

    if (!mounted) return;

    // Navigate to Detailed Performance & Gap Analysis Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BattleAnalysisScreen(
          testTitle: widget.testTitle,
          myScore: myScore,
          oppScore: oppScore,
          oppName: oppName,
          questions: widget.questions,
          myAnswers: myAnswers,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _qTimer?.cancel();
    _battleService.cancelSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (roomId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1A237E)),
              const SizedBox(height: 16),
              Text("Matching Competitor...",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _battleService.getRoomStream(roomId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        Map roomData = snapshot.data!.snapshot.value as Map;
        String status = roomData['status'] ?? 'waiting';

        if (status == 'playing' && _qTimer == null) {
          _startTimer();
        }

        if (status == 'waiting') {
          return Scaffold(
            appBar: AppBar(
                title: const Text("1v1 Quiz Battle"),
                backgroundColor: const Color(0xFF1A237E)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text("Searching Live Competitor...",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      await _battleService.cancelSearch();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("Cancel Search",
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          );
        }

        Map p1 = roomData['player1'] ?? {};
        Map p2 = roomData['player2'] ?? {};
        bool isP1 = p1['uid'] == currentUid;

        Map myData = isP1 ? p1 : p2;
        Map oppData = isP1 ? p2 : p1;

        var qData = widget.questions[currentQuestionIndex];
        List options = qData['options'] is List
            ? qData['options']
            : (qData['options'] as Map).values.toList();
        int correctIndex = qData['correctIndex'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A237E),
            title: Text(widget.testTitle,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white)),
          ),
          body: Column(
            children: [
              // REALTIME SCOREBOARD & COMBO INDICATOR
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1A237E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(myData['name'] ?? 'You',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        Text("${myData['score'] ?? 0} pts",
                            style: GoogleFonts.poppins(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        if (streakCount >= 2)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text("🔥 COMBO x$streakCount",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    // COUNTDOWN TIMER
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: _secondsLeft / 10,
                            color: _secondsLeft <= 3
                                ? Colors.redAccent
                                : Colors.amber,
                            backgroundColor: Colors.white24,
                            strokeWidth: 4,
                          ),
                        ),
                        Text("$_secondsLeft",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(oppData['name'] ?? 'Opponent',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        Text("${oppData['score'] ?? 0} pts",
                            style: GoogleFonts.poppins(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // QUESTION & OPTIONS ARENA
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Question ${currentQuestionIndex + 1}/${widget.questions.length}",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.indigo)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(qData['questionText'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(options.length, (optIdx) {
                        Color tileColor = Colors.white;
                        if (selectedOption != null) {
                          if (optIdx == correctIndex) {
                            tileColor = Colors.green.shade100;
                          } else if (optIdx == selectedOption) {
                            tileColor = Colors.red.shade100;
                          }
                        }

                        return Card(
                          color: tileColor,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(options[optIdx].toString(),
                                style: GoogleFonts.poppins(fontSize: 14)),
                            onTap: () => _answerQuestion(optIdx, correctIndex),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
