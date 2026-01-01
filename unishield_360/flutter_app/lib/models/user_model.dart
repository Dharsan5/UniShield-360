/// User model for UniShield 360
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String gender; // 'male', 'female', or 'unknown'
  final String role; // 'student', 'admin', 'security'
  final bool isVerified;
  final double voiceConfidence;
  final DateTime createdAt;
  final List<String> emergencyContacts;
  final String? profileImageUrl;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.gender,
    this.role = 'student',
    this.isVerified = false,
    this.voiceConfidence = 0.0,
    required this.createdAt,
    this.emergencyContacts = const [],
    this.profileImageUrl,
    this.phoneNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? 'unknown',
      role: map['role'] ?? 'student',
      isVerified: map['isVerified'] ?? false,
      voiceConfidence: (map['voiceConfidence'] ?? 0.0).toDouble(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      emergencyContacts: List<String>.from(map['emergencyContacts'] ?? []),
      profileImageUrl: map['profileImageUrl'],
      phoneNumber: map['phoneNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'gender': gender,
      'role': role,
      'isVerified': isVerified,
      'voiceConfidence': voiceConfidence,
      'createdAt': createdAt,
      'emergencyContacts': emergencyContacts,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? gender,
    String? role,
    bool? isVerified,
    double? voiceConfidence,
    DateTime? createdAt,
    List<String>? emergencyContacts,
    String? profileImageUrl,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      voiceConfidence: voiceConfidence ?? this.voiceConfidence,
      createdAt: createdAt ?? this.createdAt,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  bool get isMale => gender == 'male';
  bool get isFemale => gender == 'female';
  bool get isAdmin => role == 'admin' || role == 'security';
}
