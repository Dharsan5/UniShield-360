import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:unishield_360/models/alert_model.dart';
import 'package:unishield_360/config/constants.dart';
import 'package:unishield_360/services/api_service.dart';

/// Location and Alert Service for Guardian Mode
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _currentPosition;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Start tracking location in background
  void startTracking({
    required Function(Position) onLocationUpdate,
    int distanceFilter = 10,
  }) {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      onLocationUpdate(position);
    });
  }

  /// Stop tracking
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Send Yellow Alert (uncomfortable, track me)
  Future<AlertResult> sendYellowAlert({
    required String userId,
    String? message,
  }) async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return AlertResult(
          success: false,
          alertId: '',
          message: 'Could not get location',
        );
      }

      // Vibrate to confirm
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }

      // Send to API
      final apiResult = await _apiService.sendAlert(
        oderId: oderId,
        alertType: AppConstants.yellowAlert,
        latitude: position.latitude,
        longitude: position.longitude,
        message: message,
      );

      // Save to Firestore
      if (apiResult.success) {
        await _saveAlertToFirestore(
          userId: userId,
          alertType: AppConstants.yellowAlert,
          position: position,
          message: message,
          apiAlertId: apiResult.alertId,
        );
      }

      return AlertResult(
        success: apiResult.success,
        alertId: apiResult.alertId,
        message: apiResult.message,
      );
    } catch (e) {
      return AlertResult(
        success: false,
        alertId: '',
        message: 'Error: $e',
      );
    }
  }

  /// Send Red Alert (EMERGENCY)
  Future<AlertResult> sendRedAlert({
    required String userId,
    String? message,
  }) async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return AlertResult(
          success: false,
          alertId: '',
          message: 'Could not get location',
        );
      }

      // Strong vibration pattern for emergency
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 500, 100, 500, 100, 500]);
      }

      // Send to API
      final apiResult = await _apiService.sendAlert(
        oderId: oderId,
        alertType: AppConstants.redAlert,
        latitude: position.latitude,
        longitude: position.longitude,
        message: message ?? 'EMERGENCY ALERT',
      );

      // Save to Firestore
      if (apiResult.success) {
        await _saveAlertToFirestore(
          userId: userId,
          alertType: AppConstants.redAlert,
          position: position,
          message: message ?? 'EMERGENCY ALERT',
          apiAlertId: apiResult.alertId,
        );
      }

      // Start continuous tracking for emergency
      startTracking(onLocationUpdate: (pos) {
        _updateAlertLocation(apiResult.alertId, pos);
      });

      return AlertResult(
        success: apiResult.success,
        alertId: apiResult.alertId,
        message: apiResult.message,
      );
    } catch (e) {
      return AlertResult(
        success: false,
        alertId: '',
        message: 'Error: $e',
      );
    }
  }

  /// Save alert to Firestore
  Future<void> _saveAlertToFirestore({
    required String userId,
    required String alertType,
    required Position position,
    String? message,
    required String apiAlertId,
  }) async {
    await _firestore.collection(FirebaseCollections.alerts).doc(apiAlertId).set({
      'userId': userId,
      'alertType': alertType,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'locationHistory': [
        {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ],
    });
  }

  /// Update alert location in Firestore
  Future<void> _updateAlertLocation(String alertId, Position position) async {
    try {
      await _firestore.collection(FirebaseCollections.alerts).doc(alertId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationHistory': FieldValue.arrayUnion([
          {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Cancel active alert
  Future<bool> cancelAlert(String alertId) async {
    try {
      stopTracking();
      await _firestore.collection(FirebaseCollections.alerts).doc(alertId).update({
        'status': 'cancelled',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error cancelling alert: $e');
      return false;
    }
  }

  /// Get active alerts for user
  Stream<List<AlertModel>> getActiveAlerts(String userId) {
    return _firestore
        .collection(FirebaseCollections.alerts)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get Google Maps URL for location
  String getGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
}

// Using AlertResult from api_service.dart
export 'api_service.dart' show AlertResult;
