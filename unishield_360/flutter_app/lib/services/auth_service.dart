import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unishield_360/models/user_model.dart';
import 'package:unishield_360/config/constants.dart';

/// Firebase Authentication Service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          gender: 'unknown', // Will be set after voice verification
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(FirebaseCollections.users)
            .doc(credential.user!.uid)
            .set(user.toMap());

        return AuthResult(success: true, user: user);
      }

      return AuthResult(success: false, error: 'Failed to create user');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = await getUserData(credential.user!.uid);
        return AuthResult(success: true, user: user);
      }

      return AuthResult(success: false, error: 'Failed to sign in');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user gender after voice verification
  Future<bool> updateUserGender({
    required String uid,
    required String gender,
    required double confidence,
  }) async {
    try {
      await _firestore.collection(FirebaseCollections.users).doc(uid).update({
        'gender': gender,
        'voiceConfidence': confidence,
        'isVerified': confidence >= AppConstants.voiceConfidenceThreshold,
      });
      return true;
    } catch (e) {
      print('Error updating gender: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact(String uid, String contact) async {
    try {
      await _firestore.collection(FirebaseCollections.users).doc(uid).update({
        'emergencyContacts': FieldValue.arrayUnion([contact]),
      });
      return true;
    } catch (e) {
      print('Error adding emergency contact: $e');
      return false;
    }
  }

  /// Remove emergency contact
  Future<bool> removeEmergencyContact(String uid, String contact) async {
    try {
      await _firestore.collection(FirebaseCollections.users).doc(uid).update({
        'emergencyContacts': FieldValue.arrayRemove([contact]),
      });
      return true;
    } catch (e) {
      print('Error removing emergency contact: $e');
      return false;
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        error: 'Password reset email sent',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}
