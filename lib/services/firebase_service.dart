import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Auth State ──────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── Sign In / Register ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(
      String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    await _createUserDocument(credential.user!, displayName: displayName);
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNew) {
        await _createUserDocument(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      // Surface the real error so the UI can display it
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── User Document ───────────────────────────────────────────────────────────

  Future<void> _createUserDocument(User user, {String? displayName}) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName ?? user.displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        savedTitles: const [],
      );
      await docRef.set(appUser.toFirestore());
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return AppUser.fromFirestore(doc);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── Saved Titles ────────────────────────────────────────────────────────────

  Future<void> saveTitle(String uid, String title) async {
    await _db.collection('users').doc(uid).update({
      'saved_titles': FieldValue.arrayUnion([title]),
    });
  }

  Future<void> unsaveTitle(String uid, String title) async {
    await _db.collection('users').doc(uid).update({
      'saved_titles': FieldValue.arrayRemove([title]),
    });
  }

  // ─── User Activity / Search History ─────────────────────────────────────────

  Future<void> logUserActivity({
    required String userId,
    required String query,
    String? contentType,
    required List<String> results,
  }) async {
    await _db.collection('user_activity').add({
      'user_id': userId,
      'query': query,
      'content_type': contentType,
      'results': results,
      // FIX: Use server timestamp for reliable ordering
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // FIX: handleError surfaces Firestore index errors in the console instead
  // of swallowing them silently, so you can see the clickable index link.
  // Also falls back gracefully so the history screen shows an error state
  // instead of an infinite spinner.
  Stream<List<SearchHistoryItem>> getUserHistory(String uid, {int limit = 20}) {
    return _db
        .collection('user_activity')
        .where('user_id', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((e) {
          // This will print the Firestore index URL in debug console.
          // Click the link to auto-create the required composite index.
          print('[History] Firestore error (check index): $e');
        })
        .map((snap) =>
            snap.docs.map((d) => SearchHistoryItem.fromFirestore(d)).toList());
  }

  Future<void> deleteHistoryItem(String docId) async {
    await _db.collection('user_activity').doc(docId).delete();
  }

  Future<void> clearUserHistory(String uid) async {
    final snap = await _db
        .collection('user_activity')
        .where('user_id', isEqualTo: uid)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
