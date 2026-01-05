/// Alert model for safety alerts
class AlertModel {
  final String id;
  final String userId;
  final String alertType; // 'yellow' or 'red'
  final double latitude;
  final double longitude;
  final String? message;
  final DateTime createdAt;
  final String status; // 'active', 'resolved', 'cancelled'
  final List<String> notifiedContacts;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.latitude,
    required this.longitude,
    this.message,
    required this.createdAt,
    this.status = 'active',
    this.notifiedContacts = const [],
    this.resolvedBy,
    this.resolvedAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      userId: map['userId'] ?? '',
      alertType: map['alertType'] ?? 'yellow',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      message: map['message'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      notifiedContacts: List<String>.from(map['notifiedContacts'] ?? []),
      resolvedBy: map['resolvedBy'],
      resolvedAt: map['resolvedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'alertType': alertType,
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'createdAt': createdAt,
      'status': status,
      'notifiedContacts': notifiedContacts,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt,
    };
  }

  bool get isEmergency => alertType == 'red';
  bool get isActive => status == 'active';
}
