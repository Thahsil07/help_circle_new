import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBootstrap {
  static Future<void> ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (snap.exists) return;

    await ref.set({
      'uid': user.uid,
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'email': user.email,
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),

      // stats (IMPORTANT)
      'helpsGiven': 0,
      'helpsReceived': 0,
      'ratingCount': 0,
      'ratingTotal': 0,
      'avgRating': 0.0,
      'badges': [],
    });
  }
}
