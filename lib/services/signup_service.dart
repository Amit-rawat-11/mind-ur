import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SignupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================================
  /// SIGN UP
  /// ================================
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    DateTime? dob, // optional DOB
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final User? user = userCredential.user;
      if (user == null) {
        debugPrint("Account creation failed. Please try again.");
        return 'Account creation failed. Please try again.';
      }

      // Update profile
      await user.updateDisplayName(name.trim());
      await user.reload();

      final DocumentReference userDoc = _firestore
          .collection('users')
          .doc(user.uid);

      final DocumentSnapshot snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'name': name.trim(),
          'photoURL': '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),

          // account flags
          'isGoogleUser': false,
          'isPremium': false,
          'isNewUser': true,

          // trial / premium
          'premiumExpiry': DateTime.now()
              .add(const Duration(days: 7))
              .millisecondsSinceEpoch,

          // optional DOB
          if (dob != null) 'dob': Timestamp.fromDate(dob),
        });
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Signup Firebase error: ${e.code}');

      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'operation-not-allowed':
          return 'Email/password accounts are disabled.';
        default:
          return e.message ?? 'Signup failed. Please try again.';
      }
    } catch (e) {
      debugPrint('❌ Signup error: $e');
      return 'An unknown error occurred. Please try again.';
    }
  }

  /// ================================
  /// LOGIN
  /// ================================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;

      // Update last sign-in (safe, non-blocking)
      if (user != null) {
        _firestore.collection('users').doc(user.uid).update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Firebase login error: ${e.code}');

      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'Account disabled. Contact support.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        default:
          return 'Login failed. Please try again.';
      }
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      return 'Something went wrong. Please try again.';
    }
  }
}
