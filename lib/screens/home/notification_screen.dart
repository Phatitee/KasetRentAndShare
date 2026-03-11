import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';
import '../chat/chat_screen.dart';
import '../contracts/contract_details_screen.dart';
import '../reviews/user_reviews_screen.dart';

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
        actions: [
          TextButton(
            onPressed: () async {
              await FirestoreService().markAllNotificationsRead(currentUserId);
            },
            child: Text(
              'อ่านทั้งหมด',
              style: TextStyle(color: AppTheme.primaryTeal),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: FirestoreService().getUserNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
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
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationTile(context, notif, currentUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, NotificationModel notif, String currentUserId) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        FirestoreService().deleteNotification(notif.id);
      },
      child: Container(
        color: notif.isRead ? Colors.white : AppTheme.accentMint.withAlpha(30),
        child: ListTile(
          onTap: () {
            // Mark as read
            if (!notif.isRead) {
              FirestoreService().markNotificationRead(notif.id);
            }
            // Navigate based on type
            _handleNotificationTap(context, notif, currentUserId);
          },
          leading: CircleAvatar(
            backgroundColor: _getNotifColor(notif.type),
            child: Icon(_getNotifIcon(notif.type), color: Colors.white, size: 20),
          ),
          title: Text(
            notif.title,
            style: TextStyle(
              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notif.createdAt),
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: !notif.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble;
      case 'contract_received':
        return Icons.description;
      case 'contract_accepted':
        return Icons.check_circle;
      case 'contract_declined':
        return Icons.cancel;
      case 'new_review':
        return Icons.star;
      case 'contract_expiring':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'new_message':
        return AppTheme.primaryTeal;
      case 'contract_received':
        return Colors.blue;
      case 'contract_accepted':
        return AppTheme.success;
      case 'contract_declined':
        return AppTheme.error;
      case 'new_review':
        return Colors.amber[700]!;
      case 'contract_expiring':
        return Colors.orange;
      default:
        return AppTheme.textHint;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return DateFormat('d MMM yyyy').format(dt);
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notif, String currentUserId) {
    final data = notif.data;
    if (data == null) return;

    switch (notif.type) {
      case 'new_message':
        if (data['chatId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: data['chatId'],
                otherUserId: data['otherUserId'] ?? '',
                otherUserName: data['otherUserName'] ?? '',
              ),
            ),
          );
        }
        break;

      case 'contract_received':
      case 'contract_accepted':
      case 'contract_declined':
      case 'contract_expiring':
        if (data['contractId'] != null) {
          _navigateToContract(context, data['contractId']);
        }
        break;

      case 'new_review':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserReviewsScreen(
              userId: currentUserId,
              userName: 'My',
            ),
          ),
        );
        break;
    }
  }

  Future<void> _navigateToContract(BuildContext context, String contractId) async {
    try {
      final firestoreService = FirestoreService();
      final doc = await firestoreService.getContract(contractId);
      if (doc != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailsScreen(contract: doc),
          ),
        );
      }
    } catch (e) {
      // ignore navigation error
    }
  }
}
