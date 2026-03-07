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
  final String messageType; // 'text' | 'image' | 'item_card' | 'contract'
  final String? itemId;
  final String? itemName;
  final String? itemImageUrl;
  final double? itemPrice;

  // Contract specific fields
  final Map<String, dynamic>? contractData;
  final String? contractStatus; // 'pending' | 'accepted' | 'declined'

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
    };
  }
}

class ChatModel {
  final String id;
  final List<String> participants;
  final String? rentalItemId;
  final String? rentalItemName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.rentalItemId,
    this.rentalItemName,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      rentalItemId: data['rentalItemId'],
      rentalItemName: data['rentalItemName'],
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'rentalItemId': rentalItemId,
      'rentalItemName': rentalItemName,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
