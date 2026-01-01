import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unishield_360/providers/auth_provider.dart';
import 'package:unishield_360/providers/chat_provider.dart';
import 'package:unishield_360/models/chat_model.dart';
import 'package:unishield_360/theme/app_theme.dart';

/// The Locker Room - Anonymous Men's Stress Sharing (Module C)
class LockerRoomScreen extends StatefulWidget {
  const LockerRoomScreen({super.key});

  @override
  State<LockerRoomScreen> createState() => _LockerRoomScreenState();
}

class _LockerRoomScreenState extends State<LockerRoomScreen> {
  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.initializeChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Locker Room'),
        backgroundColor: AppTheme.broCodeColor.withOpacity(0.1),
      ),
      body: chatProvider.currentRoom == null
          ? _buildRoomSelection(chatProvider)
          : _buildChatRoom(chatProvider),
    );
  }

  Widget _buildRoomSelection(ChatProvider chatProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.broCodeColor,
                  AppTheme.broCodeColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.forum,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'BroCode',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anonymous peer support. Share your stress, get support.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Community Guidelines
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.broCodeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.broCodeColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.broCodeColor),
                    const SizedBox(width: 8),
                    Text(
                      'Community Guidelines',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.broCodeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('• Be supportive and kind to others'),
                const Text('• No hate speech or bullying'),
                const Text('• Everything shared here is anonymous'),
                const Text('• Messages are AI-moderated for safety'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Chat Rooms
          const Text(
            'Choose a Room',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (chatProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ...chatProvider.rooms.map((room) => _RoomCard(
                  room: room,
                  onTap: () async {
                    await chatProvider.joinRoom(room.id);
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildChatRoom(ChatProvider chatProvider) {
    return Column(
      children: [
        // Room header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.broCodeColor.withOpacity(0.1),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  chatProvider.leaveRoom();
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatProvider.currentRoom!.topic,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${chatProvider.currentRoom!.activeUsers} online',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.people, color: AppTheme.broCodeColor),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: chatProvider.getMessagesStream(chatProvider.currentRoom!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        'Be the first to share',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _MessageBubble(
                    message: message,
                    onSupport: () {
                      final authProvider = context.read<AuthProvider>();
                      chatProvider.supportMessage(
                        message.id,
                        authProvider.user?.uid ?? '',
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        // Message input
        _MessageInput(
          onSend: (text) async {
            final authProvider = context.read<AuthProvider>();
            final success = await chatProvider.sendMessage(
              roomId: chatProvider.currentRoom!.id,
              userId: authProvider.user?.uid ?? '',
              content: text,
            );

            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(chatProvider.error ?? 'Failed to send message'),
                  backgroundColor: AppTheme.emergencyRed,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.broCodeColor.withOpacity(0.1),
          child: Icon(
            _getIcon(),
            color: AppTheme.broCodeColor,
          ),
        ),
        title: Text(
          room.topic,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          room.description,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${room.activeUsers}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.broCodeColor,
              ),
            ),
            Text(
              'online',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (room.topic.toLowerCase()) {
      case 'academic stress':
        return Icons.school;
      case 'family pressure':
        return Icons.family_restroom;
      case 'career anxiety':
        return Icons.work;
      default:
        return Icons.chat;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onSupport;

  const _MessageBubble({
    required this.message,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: AppTheme.broCodeColor.withOpacity(0.1),
            child: Text(
              message.anonymousAvatar,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.anonymousName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                // Support button
                Row(
                  children: [
                    GestureDetector(
                      onTap: onSupport,
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 18,
                            color: message.supportCount > 0
                                ? Colors.red
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${message.supportCount} Support',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // TODO: Reply functionality
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _MessageInput extends StatefulWidget {
  final Function(String) onSend;

  const _MessageInput({required this.onSend});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                onChanged: (value) {
                  setState(() {
                    _hasText = value.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Share what\'s on your mind...',
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                backgroundColor:
                    _hasText ? AppTheme.broCodeColor : Colors.grey[300],
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _hasText
                      ? () {
                          widget.onSend(_controller.text.trim());
                          _controller.clear();
                          setState(() {
                            _hasText = false;
                          });
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
