import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await _ensureUserDoc(cred.user!);
    return cred;
  }

  Future<UserCredential> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await cred.user?.updateDisplayName(displayName.trim());
    await _ensureUserDoc(cred.user!);

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'helpsGiven': 0,
        'helpsReceived': 0,
        'avgRating': 0.0,
      });
    } else {
      await ref.set({
        'name': user.displayName ?? data['name'] ?? 'User',
        'email': user.email ?? data['email'] ?? '',
        'photoUrl': user.photoURL ?? data['photoUrl'] ?? '',
      }, SetOptions(merge: true));
    }
  }
}
