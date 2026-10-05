import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/battle_service.dart';

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
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  Future<void> _startMatchmaking() async {
    String? rId = await _battleService.findOrMatchOpponent(widget.testTitle, widget.questions);
    if (mounted) {
      setState(() {
        roomId = rId;
      });
    }

    // 8 Seconds Timeout -> AI Bot Fallback
    Future.delayed(const Duration(seconds: 8), () async {
      if (isSearching && mounted) {
        await _battleService.cancelSearch();
        String botRoomId = await _battleService.createBotRoom(widget.testTitle, widget.questions);
        _battleService.startBotSimulation(botRoomId, widget.questions.length);

        if (mounted) {
          setState(() {
            roomId = botRoomId;
            isSearching = false;
            isBotMatch = true;
          });
        }
      }
    });
  }

  void _answerQuestion(int optIdx, int correctIdx) {
    if (selectedOption != null) return;

    setState(() {
      selectedOption = optIdx;
      if (optIdx == correctIdx) {
        myScore += 2;
      }
    });

    bool isPlayer1 = true; 
    _battleService.updateMyScore(roomId!, isPlayer1, myScore, currentQuestionIndex + 1);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedOption = null;
        });
      } else {
        _finishMatch();
      }
    });
  }

  void _finishMatch() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("MATCH COMPLETED!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Your Final Score: $myScore pts", style: GoogleFonts.poppins(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit Arena", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
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
              Text("Finding Opponent...", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Connecting to live player or AI Bot...", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _battleService.getRoomStream(roomId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        Map roomData = snapshot.data!.snapshot.value as Map;
        String status = roomData['status'] ?? 'waiting';

        if (status == 'waiting') {
          return Scaffold(
            appBar: AppBar(title: const Text("1v1 Quiz Battle"), backgroundColor: const Color(0xFF1A237E)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text("Searching Live Competitor...", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      await _battleService.cancelSearch();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("Cancel Search", style: TextStyle(color: Colors.white)),
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
        List options = qData['options'] is List ? qData['options'] : (qData['options'] as Map).values.toList();
        int correctIndex = qData['correctIndex'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A237E),
            title: Text(widget.testTitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
          ),
          body: Column(
            children: [
              // REALTIME LIVE SCOREBOARD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1A237E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(myData['name'] ?? 'You', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("${myData['score'] ?? 0} pts", style: GoogleFonts.poppins(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                      child: Text("VS", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      children: [
                        Text(oppData['name'] ?? 'Opponent', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("${oppData['score'] ?? 0} pts", style: GoogleFonts.poppins(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // QUESTION ARENA
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Question ${currentQuestionIndex + 1}/${widget.questions.length}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(qData['questionText'] ?? '', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
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
                            title: Text(options[optIdx].toString(), style: GoogleFonts.poppins(fontSize: 14)),
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
