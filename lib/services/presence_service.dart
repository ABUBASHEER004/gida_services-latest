import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================
  // USER ONLINE
  // ==========================
  static Future<void> setOnline() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================
  // USER OFFLINE
  // ==========================
  static Future<void> setOffline() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================
  // UPDATE LAST SEEN
  // ==========================
  static Future<void> updateLastSeen() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}