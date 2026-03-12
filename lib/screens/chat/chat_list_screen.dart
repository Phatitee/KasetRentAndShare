import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_message_model.dart';
import '../../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('chat_title')),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: FirestoreService().getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${l.tr('error')}: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.tr('no_chats'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.tr('no_chats_sub'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return Dismissible(
                key: Key(chat.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: AppTheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('ลบการสนทนา?'),
                      content: const Text('ข้อความทั้งหมดจะถูกลบและไม่สามารถกู้คืนได้'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ยกเลิก'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                          child: const Text('ลบ'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  FirestoreService().deleteChat(chat.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบการสนทนาแล้ว')),
                  );
                },
                child: _ChatListItem(
                  chat: chat,
                  currentUserId: currentUserId,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Get the other user's ID
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final unreadCount = chat.getUnreadFor(currentUserId);
    final hasUnread = unreadCount > 0;

    return FutureBuilder(
      future: FirestoreService().getUserData(otherUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;
        final otherUserName = otherUser?.name ?? 'Unknown User';

        return ListTile(
          onTap: () {
            // Mark as read when opening
            FirestoreService().markChatAsRead(chat.id, currentUserId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chat.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  rentalItemId: chat.rentalItemId,
                  rentalItemName: chat.rentalItemName,
                  rentalRequestId: chat.rentalRequestId,
                  rentalRequestName: chat.rentalRequestName,
                ),
              ),
            );          },
          leading: UserAvatar(
            photoUrl: otherUser?.photoUrl,
            name: otherUserName,
            radius: 28,
            fontSize: 18,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  otherUserName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chat.lastMessageTime != null)
                Text(
                  _formatTime(chat.lastMessageTime!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasUnread ? AppTheme.primaryTeal : AppTheme.textSecondary,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chat.rentalItemName != null) ...[
                Text(
                  chat.rentalItemName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (chat.lastMessage != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: hasUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          isThreeLine: chat.rentalItemName != null && chat.lastMessage != null,
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('E').format(time); // Day name
    } else {
      return DateFormat('d/M').format(time);
    }
  }
}
