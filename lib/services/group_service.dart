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

  // Real Name Fallback Logic
  String _getUserDisplayName(User user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    } else if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@')[0];
    } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return user.phoneNumber!;
    }
    return "User_${user.uid.substring(0, 4)}";
  }

  Future<String?> createGroup(String groupName) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String groupCode = _generateGroupCode();
      String userName = _getUserDisplayName(user);

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

      String userName = _getUserDisplayName(user);

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

    String userName = _getUserDisplayName(user);

    await _db.collection('study_groups').doc(groupCode).update({
      'memberDetails.${user.uid}.name': userName,
      'memberDetails.${user.uid}.totalScore': FieldValue.increment(newScore),
      'memberDetails.${user.uid}.testsGiven': FieldValue.increment(1),
    });
  }

  // Enhanced Doubt Wall Methods
  Future<void> postDoubt({
    required String groupCode,
    required String questionText,
    required String testTitle,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = _getUserDisplayName(user);

    await _db
        .collection('study_groups')
        .doc(groupCode)
        .collection('doubts')
        .add({
      'askedBy': userName,
      'userId': user.uid,
      'questionText': questionText,
      'testTitle': testTitle,
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

    String userName = _getUserDisplayName(user);

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
