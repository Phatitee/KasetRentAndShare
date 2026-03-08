import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_message_model.dart';
import '../chat/chat_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentUserId =
        Provider.of<AuthService>(context, listen: false).currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('notifications')),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: FirestoreService().getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];
          // Filter to only chats with unread messages
          final unreadChats = chats
              .where((c) => c.getUnreadFor(currentUserId) > 0)
              .toList();

          if (unreadChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.tr('no_notifications'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.tr('no_notifications_sub'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: unreadChats.length,
            itemBuilder: (context, index) {
              final chat = unreadChats[index];
              final unread = chat.getUnreadFor(currentUserId);
              final otherUserId = chat.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return FutureBuilder(
                future: FirestoreService().getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  final otherUserName =
                      userSnapshot.data?.name ?? '...';

                  return ListTile(
                    onTap: () {
                      FirestoreService()
                          .markChatAsRead(chat.id, currentUserId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            otherUserId: otherUserId,
                            otherUserName: otherUserName,
                            rentalItemId: chat.rentalItemId,
                            rentalItemName: chat.rentalItemName,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryTeal,
                      child: const Icon(Icons.chat, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      '$otherUserName ${l.tr('notif_new_messages')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      chat.lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
