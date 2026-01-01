import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unishield_360/models/chat_model.dart';
import 'package:unishield_360/config/constants.dart';
import 'package:unishield_360/services/api_service.dart';

/// Chat Provider for The Locker Room (anonymous stress sharing)
class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  List<ChatMessage> _messages = [];
  List<ChatRoom> _rooms = [];
  ChatRoom? _currentRoom;
  bool _isLoading = false;
  String? _error;
  Map<String, String> _userAvatars = {}; // userId -> avatar emoji

  // Getters
  List<ChatMessage> get messages => _messages;
  List<ChatRoom> get rooms => _rooms;
  ChatRoom? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize chat rooms
  Future<void> initializeChatRooms() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create default rooms if they don't exist
      final defaultRooms = [
        {
          'topic': 'Academic Stress',
          'description': 'Share your academic challenges and get support',
        },
        {
          'topic': 'Family Pressure',
          'description': 'Discuss family-related stress anonymously',
        },
        {
          'topic': 'Career Anxiety',
          'description': 'Talk about career worries and future concerns',
        },
        {
          'topic': 'General Chat',
          'description': 'Open space for any concerns',
        },
      ];

      for (final room in defaultRooms) {
        final query = await _firestore
            .collection(FirebaseCollections.chatRooms)
            .where('topic', isEqualTo: room['topic'])
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          await _firestore.collection(FirebaseCollections.chatRooms).add({
            ...room,
            'createdAt': FieldValue.serverTimestamp(),
            'messageCount': 0,
            'activeUsers': 0,
            'isActive': true,
          });
        }
      }

      await loadRooms();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load available chat rooms
  Future<void> loadRooms() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.chatRooms)
          .where('isActive', isEqualTo: true)
          .orderBy('topic')
          .get();

      _rooms = snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Join a chat room
  Future<void> joinRoom(String roomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection(FirebaseCollections.chatRooms)
          .doc(roomId)
          .get();

      if (doc.exists) {
        _currentRoom = ChatRoom.fromMap(doc.data()!, doc.id);

        // Increment active users
        await _firestore
            .collection(FirebaseCollections.chatRooms)
            .doc(roomId)
            .update({
          'activeUsers': FieldValue.increment(1),
        });
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    if (_currentRoom == null) return;

    try {
      await _firestore
          .collection(FirebaseCollections.chatRooms)
          .doc(_currentRoom!.id)
          .update({
        'activeUsers': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error leaving room: $e');
    }

    _currentRoom = null;
    _messages = [];
    notifyListeners();
  }

  /// Stream messages for current room
  Stream<List<ChatMessage>> getMessagesStream(String roomId) {
    return _firestore
        .collection(FirebaseCollections.chatMessages)
        .where('roomId', isEqualTo: roomId)
        .where('isModerated', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get or create anonymous avatar for user
  Map<String, String> getAnonymousAvatar(String oderId) {
    if (!_userAvatars.containsKey(oderId)) {
      final avatar = AnonymousAvatars.getRandomAvatar();
      _userAvatars[oderId] = avatar['emoji']!;
      return avatar;
    }
    
    // Find matching avatar
    for (final avatar in AnonymousAvatars.avatars) {
      if (avatar['emoji'] == _userAvatars[oderId]) {
        return avatar;
      }
    }
    
    return AnonymousAvatars.getRandomAvatar();
  }

  /// Send a message (with moderation)
  Future<bool> sendMessage({
    required String roomId,
    required String userId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;
    if (content.length > AppConstants.maxMessageLength) {
      _error = 'Message is too long (max ${AppConstants.maxMessageLength} characters)';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, moderate the message
      final moderationResult = await _apiService.moderateText(content, userId: userId);

      if (!moderationResult.safeToPost) {
        _error = moderationResult.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get anonymous avatar
      final avatar = getAnonymousAvatar(userId);

      // Create message
      await _firestore.collection(FirebaseCollections.chatMessages).add({
        'roomId': roomId,
        'userId': oderId,
        'content': content.trim(),
        'anonymousName': avatar['name'],
        'anonymousAvatar': avatar['emoji'],
        'createdAt': FieldValue.serverTimestamp(),
        'isModerated': true,
        'toxicityScore': moderationResult.toxicityScore,
        'supportCount': 0,
        'supportedBy': [],
      });

      // Update room message count
      await _firestore
          .collection(FirebaseCollections.chatRooms)
          .doc(roomId)
          .update({
        'messageCount': FieldValue.increment(1),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Support (like) a message
  Future<bool> supportMessage(String messageId, String oderId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final supportedBy = List<String>.from(data['supportedBy'] ?? []);

        if (supportedBy.contains(oderId)) {
          // Already supported, remove support
          await _firestore
              .collection(FirebaseCollections.chatMessages)
              .doc(messageId)
              .update({
            'supportCount': FieldValue.increment(-1),
            'supportedBy': FieldValue.arrayRemove([oderId]),
          });
        } else {
          // Add support
          await _firestore
              .collection(FirebaseCollections.chatMessages)
              .doc(messageId)
              .update({
            'supportCount': FieldValue.increment(1),
            'supportedBy': FieldValue.arrayUnion([oderId]),
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Report a message
  Future<bool> reportMessage(String messageId, String reason) async {
    try {
      await _firestore.collection('reported_messages').add({
        'messageId': messageId,
        'reason': reason,
        'reportedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
