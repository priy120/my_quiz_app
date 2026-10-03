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

  Future<String?> createGroup(String groupName) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String groupCode = _generateGroupCode();
      String userName = user.displayName ?? "Student";

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
      print("Error creating group: $e");
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

      String userName = user.displayName ?? "Student";

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
      print("Error joining group: $e");
      return false;
    }
  }

  Stream<DocumentSnapshot> getGroupDetails(String groupCode) {
    return _db.collection('study_groups').doc(groupCode).snapshots();
  }

  Future<void> updateGroupScore(String groupCode, double newScore) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('study_groups').doc(groupCode).update({
      'memberDetails.${user.uid}.totalScore': FieldValue.increment(newScore),
      'memberDetails.${user.uid}.testsGiven': FieldValue.increment(1),
    });
  }
}
