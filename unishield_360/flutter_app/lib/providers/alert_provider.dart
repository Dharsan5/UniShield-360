import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:unishield_360/models/alert_model.dart';
import 'package:unishield_360/services/location_service.dart';
import 'package:unishield_360/services/api_service.dart';

/// Alert Provider for Guardian Mode state management
class AlertProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  bool _isTracking = false;
  String? _activeAlertId;
  String? _activeAlertType;
  Position? _currentPosition;
  String? _error;
  List<AlertModel> _activeAlerts = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  bool get hasActiveAlert => _activeAlertId != null;
  String? get activeAlertId => _activeAlertId;
  String? get activeAlertType => _activeAlertType;
  Position? get currentPosition => _currentPosition;
  String? get error => _error;
  List<AlertModel> get activeAlerts => _activeAlerts;

  /// Initialize location services
  Future<bool> initializeLocation() async {
    return await _locationService.checkPermissions();
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    _currentPosition = await _locationService.getCurrentPosition();

    _isLoading = false;
    notifyListeners();

    return _currentPosition;
  }

  /// Send Yellow Alert (I'm uncomfortable, track me)
  Future<bool> sendYellowAlert({
    required String userId,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _locationService.sendYellowAlert(
      userId: userId,
      message: message,
    );

    if (result.success) {
      _activeAlertId = result.alertId;
      _activeAlertType = 'yellow';
      _isTracking = true;
    } else {
      _error = result.message;
    }

    _isLoading = false;
    notifyListeners();

    return result.success;
  }

  /// Send Red Alert (EMERGENCY)
  Future<bool> sendRedAlert({
    required String userId,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _locationService.sendRedAlert(
      userId: userId,
      message: message,
    );

    if (result.success) {
      _activeAlertId = result.alertId;
      _activeAlertType = 'red';
      _isTracking = true;
      
      // Start tracking location updates
      _locationService.startTracking(
        onLocationUpdate: (position) {
          _currentPosition = position;
          notifyListeners();
        },
      );
    } else {
      _error = result.message;
    }

    _isLoading = false;
    notifyListeners();

    return result.success;
  }

  /// Cancel active alert
  Future<bool> cancelAlert() async {
    if (_activeAlertId == null) return false;

    _isLoading = true;
    notifyListeners();

    final success = await _locationService.cancelAlert(_activeAlertId!);

    if (success) {
      _activeAlertId = null;
      _activeAlertType = null;
      _isTracking = false;
      _locationService.stopTracking();
    }

    _isLoading = false;
    notifyListeners();

    return success;
  }

  /// Subscribe to user's active alerts
  void subscribeToAlerts(String userId) {
    _locationService.getActiveAlerts(userId).listen((alerts) {
      _activeAlerts = alerts;
      notifyListeners();
    });
  }

  /// Get Google Maps URL for current location
  String? getLocationUrl() {
    if (_currentPosition == null) return null;
    return _locationService.getGoogleMapsUrl(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }
}
