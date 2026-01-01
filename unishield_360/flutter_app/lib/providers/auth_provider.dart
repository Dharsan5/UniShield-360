import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unishield_360/models/user_model.dart';
import 'package:unishield_360/services/auth_service.dart';
import 'package:unishield_360/services/api_service.dart';
import 'dart:io';

/// Authentication Provider for state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isVoiceVerifying = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isVerified => _user?.isVerified ?? false;
  bool get isMale => _user?.isMale ?? false;
  bool get isFemale => _user?.isFemale ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isVoiceVerifying => _isVoiceVerifying;

  AuthProvider() {
    _init();
  }

  /// Initialize - check if user is already logged in
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _user = await _authService.getUserData(currentUser.uid);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
    );

    _isLoading = false;

    if (result.success) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signIn(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result.success) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Verify voice for gender detection
  Future<VoiceVerificationResult> verifyVoice(File audioFile) async {
    _isVoiceVerifying = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.verifyVoice(audioFile);

    if (result.success && _user != null) {
      // Update user gender in Firestore
      await _authService.updateUserGender(
        uid: _user!.uid,
        gender: result.gender,
        confidence: result.confidence,
      );

      // Update local user model
      _user = _user!.copyWith(
        gender: result.gender,
        voiceConfidence: result.confidence,
        isVerified: result.confidence >= 0.7,
      );
    } else {
      _error = result.message;
    }

    _isVoiceVerifying = false;
    notifyListeners();
    return result;
  }

  /// Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;

    final success = await _authService.updateUserProfile(_user!.uid, data);
    if (success) {
      // Refresh user data
      _user = await _authService.getUserData(_user!.uid);
      notifyListeners();
    }
    return success;
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact(String contact) async {
    if (_user == null) return false;

    final success = await _authService.addEmergencyContact(_user!.uid, contact);
    if (success) {
      _user = _user!.copyWith(
        emergencyContacts: [..._user!.emergencyContacts, contact],
      );
      notifyListeners();
    }
    return success;
  }

  /// Remove emergency contact
  Future<bool> removeEmergencyContact(String contact) async {
    if (_user == null) return false;

    final success = await _authService.removeEmergencyContact(_user!.uid, contact);
    if (success) {
      final contacts = List<String>.from(_user!.emergencyContacts);
      contacts.remove(contact);
      _user = _user!.copyWith(emergencyContacts: contacts);
      notifyListeners();
    }
    return success;
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.resetPassword(email);

    _isLoading = false;
    _error = result.error;
    notifyListeners();

    return result.success;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
