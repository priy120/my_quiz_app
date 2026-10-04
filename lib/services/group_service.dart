import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate Unique Group Code
  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Fetch real name directly from User Profile / Firestore
  Future<String> getUserRealName() async {
    User? user = _auth.currentUser;
    if (user == null) return "Student";

    try {
      // 1. Try reading from Firestore User Document
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data['name'] != null && data['name'].toString().trim().isNotEmpty) {
          return data['name'].toString().trim();
        }
        if (data != null && data['fullName'] != null && data['fullName'].toString().trim().isNotEmpty) {
          return data['fullName'].toString().trim();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user name from Firestore: $e");
    }

    // 2. Try FirebaseAuth Display Name
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }

    // 3. Email Prefix Fallback
    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@')[0];
    }

    return "Student_${user.uid.substring(0, 4)}";
  }

  // Update UserName across User collection and Active Group
  Future<void> updateUserName(String groupCode, String newName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(newName);

    // Update in users collection
    await _db.collection('users').doc(user.uid).set({
      'name': newName,
    }, SetOptions(merge: true));

    // Update in active study group
    String formattedGroupCode = groupCode.trim().toUpperCase();
    await _db.collection('study_groups').doc(formattedGroupCode).set({
      'memberDetails': {
        user.uid: {
          'name': newName,
        }
      }
    }, SetOptions(merge: true));
  }

  // Create New Study Group
  Future<String?> createGroup(String groupName) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String groupCode = _generateGroupCode();
      String userName = await getUserRealName();

      await _db.collection('study_groups').doc(groupCode).set({
        'groupCode': groupCode,
        'groupName': groupName,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user.uid],
        'memberDetails': {
          user.uid: {
            'name': userName,
            'totalScore': 0,
            'testsGiven': 0,
          }
        }
      });

      return groupCode;
    } catch (e) {
      debugPrint("Error creating group: $e");
      return null;
    }
  }

  // Join Existing Study Group
  Future<bool> joinGroup(String groupCode) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      String formattedGroupCode = groupCode.trim().toUpperCase();
      DocumentSnapshot doc = await _db.collection('study_groups').doc(formattedGroupCode).get();

      if (!doc.exists) return false;

      String userName = await getUserRealName();

      await _db.collection('study_groups').doc(formattedGroupCode).set({
        'members': FieldValue.arrayUnion([user.uid]),
        'memberDetails': {
          user.uid: {
            'name': userName,
            'totalScore': 0,
            'testsGiven': 0,
          }
        }
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint("Error joining group: $e");
      return false;
    }
  }

  // Get Group Stream Details
  Stream<DocumentSnapshot> getGroupDetails(String groupCode) {
    String formattedGroupCode = groupCode.trim().toUpperCase();
    return _db.collection('study_groups').doc(formattedGroupCode).snapshots();
  }

  // Update Score in Group Leaderboard (Fixed & Improved)
  Future<void> updateGroupScore(String groupCode, double newScore, {bool isReattempt = false}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Reattempt par points add nahi honge
    if (isReattempt) {
      debugPrint("Reattempt detected: Group score will not be updated.");
      return;
    }

    String formattedGroupCode = groupCode.trim().toUpperCase();

    try {
      String userName = await getUserRealName();

      await _db.collection('study_groups').doc(formattedGroupCode).set({
        'memberDetails': {
          user.uid: {
            'name': userName,
            'totalScore': FieldValue.increment(newScore),
            'testsGiven': FieldValue.increment(1),
          }
        }
      }, SetOptions(merge: true));

      debugPrint("Group score successfully updated for $formattedGroupCode");
    } catch (e) {
      debugPrint("Error updating group score: $e");
    }
  }

  // Post Doubt inside Group
  Future<void> postDoubt({
    required String groupCode,
    required String questionText,
    required String testTitle,
    String? categoryName,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = await getUserRealName();
    String fullTag = (categoryName != null && categoryName.isNotEmpty)
        ? "$categoryName - $testTitle"
        : testTitle;

    String formattedGroupCode = groupCode.trim().toUpperCase();

    await _db
        .collection('study_groups')
        .doc(formattedGroupCode)
        .collection('doubts')
        .add({
      'askedBy': userName,
      'userId': user.uid,
      'questionText': questionText,
      'testTitle': fullTag,
      'createdAt': FieldValue.serverTimestamp(),
      'answers': [],
    });
  }

  // Reply / Answer to a Doubt
  Future<void> addDoubtAnswer({
    required String groupCode,
    required String doubtId,
    required String replyText,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = await getUserRealName();
    String formattedGroupCode = groupCode.trim().toUpperCase();

    await _db
        .collection('study_groups')
        .doc(formattedGroupCode)
        .collection('doubts')
        .doc(doubtId)
        .update({
      'answers': FieldValue.arrayUnion([
        {
          'answeredBy': userName,
          'answerText': replyText,
          'time': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    });
  }

  // Get Doubts Stream
  Stream<QuerySnapshot> getGroupDoubts(String groupCode) {
    String formattedGroupCode = groupCode.trim().toUpperCase();
    return _db
        .collection('study_groups')
        .doc(formattedGroupCode)
        .collection('doubts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
