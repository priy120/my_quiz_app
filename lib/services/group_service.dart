import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateGroupCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
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
      // Fallback if Firestore read fails
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

  Future<void> updateUserName(String groupCode, String newName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(newName);
    
    // Update in users collection
    await _db.collection('users').doc(user.uid).set({
      'name': newName,
    }, SetOptions(merge: true));

    // Update in active study group
    await _db.collection('study_groups').doc(groupCode).update({
      'memberDetails.${user.uid}.name': newName,
    });
  }

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
      return null;
    }
  }

  Future<bool> joinGroup(String groupCode) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc =
          await _db.collection('study_groups').doc(groupCode.trim().toUpperCase()).get();

      if (!doc.exists) return false;

      String userName = await getUserRealName();

      await _db.collection('study_groups').doc(groupCode.trim().toUpperCase()).update({
        'members': FieldValue.arrayUnion([user.uid]),
        'memberDetails.${user.uid}': {
          'name': userName,
          'totalScore': 0,
          'testsGiven': 0,
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<DocumentSnapshot> getGroupDetails(String groupCode) {
    return _db.collection('study_groups').doc(groupCode).snapshots();
  }

  Future<void> updateGroupScore(String groupCode, double newScore) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = await getUserRealName();

    await _db.collection('study_groups').doc(groupCode).update({
      'memberDetails.${user.uid}.name': userName,
      'memberDetails.${user.uid}.totalScore': FieldValue.increment(newScore),
      'memberDetails.${user.uid}.testsGiven': FieldValue.increment(1),
    });
  }

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

    await _db
        .collection('study_groups')
        .doc(groupCode)
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

  Future<void> addDoubtAnswer({
    required String groupCode,
    required String doubtId,
    required String replyText,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = await getUserRealName();

    await _db
        .collection('study_groups')
        .doc(groupCode)
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

  Stream<QuerySnapshot> getGroupDoubts(String groupCode) {
    return _db
        .collection('study_groups')
        .doc(groupCode)
        .collection('doubts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
