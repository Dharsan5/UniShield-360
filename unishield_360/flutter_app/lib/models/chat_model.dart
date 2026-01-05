/// Chat message model for anonymous stress sharing
class ChatMessage {
  final String id;
  final String userId;
  final String content;
  final String anonymousName; // e.g., "Anonymous Tiger"
  final String anonymousAvatar;
  final DateTime createdAt;
  final bool isModerated;
  final double toxicityScore;
  final int supportCount; // like count for supportive messages
  final List<String> supportedBy;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.anonymousName,
    required this.anonymousAvatar,
    required this.createdAt,
    this.isModerated = true,
    this.toxicityScore = 0.0,
    this.supportCount = 0,
    this.supportedBy = const [],
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      anonymousName: map['anonymousName'] ?? 'Anonymous',
      anonymousAvatar: map['anonymousAvatar'] ?? '🐯',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isModerated: map['isModerated'] ?? true,
      toxicityScore: (map['toxicityScore'] ?? 0.0).toDouble(),
      supportCount: map['supportCount'] ?? 0,
      supportedBy: List<String>.from(map['supportedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'anonymousName': anonymousName,
      'anonymousAvatar': anonymousAvatar,
      'createdAt': createdAt,
      'isModerated': isModerated,
      'toxicityScore': toxicityScore,
      'supportCount': supportCount,
      'supportedBy': supportedBy,
    };
  }
}

/// Chat room model
class ChatRoom {
  final String id;
  final String topic;
  final String description;
  final DateTime createdAt;
  final int messageCount;
  final int activeUsers;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.topic,
    required this.description,
    required this.createdAt,
    this.messageCount = 0,
    this.activeUsers = 0,
    this.isActive = true,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      topic: map['topic'] ?? 'General',
      description: map['description'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      messageCount: map['messageCount'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'description': description,
      'createdAt': createdAt,
      'messageCount': messageCount,
      'activeUsers': activeUsers,
      'isActive': isActive,
    };
  }
}

/// List of anonymous avatars for the chat
class AnonymousAvatars {
  static const List<Map<String, String>> avatars = [
    {'name': 'Anonymous Tiger', 'emoji': '🐯'},
    {'name': 'Anonymous Bear', 'emoji': '🐻'},
    {'name': 'Anonymous Wolf', 'emoji': '🐺'},
    {'name': 'Anonymous Eagle', 'emoji': '🦅'},
    {'name': 'Anonymous Lion', 'emoji': '🦁'},
    {'name': 'Anonymous Fox', 'emoji': '🦊'},
    {'name': 'Anonymous Owl', 'emoji': '🦉'},
    {'name': 'Anonymous Dolphin', 'emoji': '🐬'},
    {'name': 'Anonymous Phoenix', 'emoji': '🔥'},
    {'name': 'Anonymous Dragon', 'emoji': '🐉'},
    {'name': 'Anonymous Hawk', 'emoji': '🦅'},
    {'name': 'Anonymous Panther', 'emoji': '🐆'},
  ];

  static Map<String, String> getRandomAvatar() {
    final random = DateTime.now().millisecondsSinceEpoch % avatars.length;
    return avatars[random];
  }
}
