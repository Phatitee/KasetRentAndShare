import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'new_message', 'contract_received', 'contract_accepted',
                     // 'contract_declined', 'new_review', 'contract_expiring'
  final String title;
  final String body;
  final Map<String, dynamic>? data; // metadata e.g. chatId, contractId
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      type: d['type'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      data: d['data'] as Map<String, dynamic>?,
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
