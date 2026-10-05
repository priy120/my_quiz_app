import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class BattleService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. AI Bot Practice Room
  Future<String> createBotRoom(String testTitle, List<Map<String, dynamic>> questions) async {
    User? user = _auth.currentUser;
    if (user == null) return '';

    String roomId = "bot_${DateTime.now().millisecondsSinceEpoch}";
    DatabaseReference roomRef = _db.ref('battle_rooms/$roomId');

    await roomRef.set({
      'roomId': roomId,
      'testTitle': testTitle,
      'status': 'playing',
      'isBotMatch': true,
      'player1': {
        'uid': user.uid,
        'name': user.displayName ?? 'Player 1',
        'score': 0,
        'currentQ': 0,
      },
      'player2': {
        'uid': 'ai_bot_99',
        'name': 'AI Opponent 🤖',
        'score': 0,
        'currentQ': 0,
      },
      'questions': questions,
      'createdAt': ServerValue.timestamp,
    });

    return roomId;
  }

  // AI Bot Smart Automation
  void startBotSimulation(String roomId, int totalQuestions) {
    int currentQ = 0;
    int botScore = 0;
    Random rnd = Random();

    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (currentQ >= totalQuestions) {
        timer.cancel();
        _db.ref('battle_rooms/$roomId').update({'status': 'completed'});
        return;
      }

      bool isCorrect = rnd.nextDouble() < 0.70; // 70% accuracy
      if (isCorrect) botScore += 2;

      currentQ++;

      _db.ref('battle_rooms/$roomId/player2').update({
        'score': botScore,
        'currentQ': currentQ,
      });
    });
  }

  // 2. Real-Time Online Matchmaking Logic
  Future<String?> findOrMatchOpponent(String testTitle, List<Map<String, dynamic>> questions) async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DatabaseReference queueRef = _db.ref('battle_queue');
    DataSnapshot queueSnap = await queueRef.get();

    if (queueSnap.exists && queueSnap.value != null) {
      Map queueData = queueSnap.value as Map;
      String? waitingUserUid;
      String? waitingRoomId;

      queueData.forEach((key, value) {
        if (key != user.uid && value['status'] == 'waiting') {
          waitingUserUid = key;
          waitingRoomId = value['roomId'];
        }
      });

      if (waitingUserUid != null && waitingRoomId != null) {
        DatabaseReference roomRef = _db.ref('battle_rooms/$waitingRoomId');

        await roomRef.update({
          'status': 'playing',
          'player2': {
            'uid': user.uid,
            'name': user.displayName ?? 'Player 2',
            'score': 0,
            'currentQ': 0,
          }
        });

        await queueRef.child(waitingUserUid!).remove();
        return waitingRoomId;
      }
    }

    String roomId = "room_${DateTime.now().millisecondsSinceEpoch}";
    DatabaseReference roomRef = _db.ref('battle_rooms/$roomId');

    await roomRef.set({
      'roomId': roomId,
      'testTitle': testTitle,
      'status': 'waiting',
      'isBotMatch': false,
      'player1': {
        'uid': user.uid,
        'name': user.displayName ?? 'Player 1',
        'score': 0,
        'currentQ': 0,
      },
      'player2': null,
      'questions': questions,
      'createdAt': ServerValue.timestamp,
    });

    await queueRef.child(user.uid).set({
      'roomId': roomId,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
    });

    return roomId;
  }

  Future<void> cancelSearch() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.ref('battle_queue/${user.uid}').remove();
    }
  }

  Future<void> updateMyScore(String roomId, bool isPlayer1, int newScore, int questionIndex) async {
    String pKey = isPlayer1 ? 'player1' : 'player2';
    await _db.ref('battle_rooms/$roomId/$pKey').update({
      'score': newScore,
      'currentQ': questionIndex,
    });
  }

  Stream<DatabaseEvent> getRoomStream(String roomId) {
    return _db.ref('battle_rooms/$roomId').onValue;
  }
}
