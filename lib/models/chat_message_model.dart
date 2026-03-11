import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  // Item card fields
  final String messageType; // 'text' | 'image' | 'item_card' | 'contract' | 'request_card' | 'status'
  final String? itemId;
  final String? itemName;
  final String? itemImageUrl;
  final double? itemPrice;

  // Contract specific fields
  final Map<String, dynamic>? contractData;
  final String? contractStatus; // 'pending' | 'accepted' | 'declined'

  // Request card fields
  final String? requestId;
  final String? requestDescription;
  final double? requestBudget;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
    this.itemId,
    this.itemName,
    this.itemImageUrl,
    this.itemPrice,
    this.contractData,
    this.contractStatus,
    this.requestId,
    this.requestDescription,
    this.requestBudget,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? 'text',
      itemId: data['itemId'],
      itemName: data['itemName'],
      itemImageUrl: data['itemImageUrl'],
      itemPrice: data['itemPrice'] != null
          ? (data['itemPrice'] as num).toDouble()
          : null,
      contractData: data['contractData'] != null ? Map<String, dynamic>.from(data['contractData']) : null,
      contractStatus: data['contractStatus'],
      requestId: data['requestId'],
      requestDescription: data['requestDescription'],
      requestBudget: data['requestBudget'] != null
          ? (data['requestBudget'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType,
      'itemId': itemId,
      'itemName': itemName,
      'itemImageUrl': itemImageUrl,
      'itemPrice': itemPrice,
      'contractData': contractData,
      'contractStatus': contractStatus,
      'requestId': requestId,
      'requestDescription': requestDescription,
      'requestBudget': requestBudget,
    };
  }
}

class ChatModel {
  final String id;
  final List<String> participants;
  final String? rentalItemId;
  final String? rentalItemName;
  final String? rentalRequestId;
  final String? rentalRequestName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final Map<String, int> unreadCount; // {userId: count}

  ChatModel({
    required this.id,
    required this.participants,
    this.rentalItemId,
    this.rentalItemName,
    this.rentalRequestId,
    this.rentalRequestName,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      rentalItemId: data['rentalItemId'],
      rentalItemName: data['rentalItemName'],
      rentalRequestId: data['rentalRequestId'],
      rentalRequestName: data['rentalRequestName'],
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] != null
          ? Map<String, int>.from(
              (data['unreadCount'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
            )
          : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'rentalItemId': rentalItemId,
      'rentalItemName': rentalItemName,
      'rentalRequestId': rentalRequestId,
      'rentalRequestName': rentalRequestName,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'unreadCount': unreadCount,
    };
  }

  /// Get unread count for a specific user
  int getUnreadFor(String userId) => unreadCount[userId] ?? 0;
}
