import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_item_model.dart';
import '../models/rental_request_model.dart';
import '../models/offer_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../models/rental_contract_model.dart';
import '../models/review_model.dart';
import 'cloudinary_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // ========== User Operations ==========

  /// Get user by ID (with proactive verification check)
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      bool isVerified = data['isVerified'] ?? false;
      int totalRentals = data['totalRentals'] ?? 0;

      // Proactive sync: If not verified in DB, check if they should be
      if (!isVerified) {
        final ownerCountRes = await _firestore
            .collection('contracts')
            .where('ownerId', isEqualTo: userId)
            .where('returnConfirmedAt', isNull: false)
            .count()
            .get();
        
        final renterCountRes = await _firestore
            .collection('contracts')
            .where('renterId', isEqualTo: userId)
            .where('returnConfirmedAt', isNull: false)
            .count()
            .get();

        final actualCount = (ownerCountRes.count ?? 0) + (renterCountRes.count ?? 0);

        if (actualCount > 0) {
          isVerified = true;
          totalRentals = actualCount;
          // Update DB in background
          _firestore.collection('users').doc(userId).update({
            'isVerified': true,
            'totalRentals': actualCount,
          });
        }
      }

      return UserModel.fromFirestore(doc).copyWith(
        isVerified: isVerified,
        totalRentals: totalRentals,
      );
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Get user data by UID (Alias for getUser)
  Future<UserModel?> getUserData(String uid) => getUser(uid);

  // ========== Rental Item Operations ==========

  /// Create rental item
  Future<String> createRentalItem(RentalItemModel item) async {
    try {
      final docRef = await _firestore.collection('rental_items').add(
            item.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create rental item: $e');
    }
  }

  /// Get rental item by ID
  Future<RentalItemModel?> getRentalItem(String id) async {
    try {
      final doc = await _firestore.collection('rental_items').doc(id).get();
      if (doc.exists) {
        return RentalItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting rental item: $e');
      return null;
    }
  }

  /// Get user's rental items
  Stream<List<RentalItemModel>> getUserRentalItems(String userId) {
    return _firestore
        .collection('rental_items')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalItemModel.fromFirestore(doc))
            .toList());
  }

  /// Get all rental items (with optional filters)
  Stream<List<RentalItemModel>> getRentalItems({
    String? category,
    String? status,
    int limit = 100, // Increased limit for client-side filtering
  }) {
    Query query = _firestore.collection('rental_items');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // Always sort by newest first for the feed
    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      var items = snapshot.docs.map((doc) => RentalItemModel.fromFirestore(doc)).toList();
      
      // Client-side filtering for 'hidden' if status not specified
      if (status == null) {
        items = items.where((item) => item.status != 'hidden').toList();
      }
      
      // Client-side filtering for category
      if (category != null && category.isNotEmpty) {
        items = items.where((item) => item.category == category).toList();
      }
      
      return items;
    });
  }

  /// Update rental item
  Future<void> updateRentalItem(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('rental_items').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update rental item: $e');
    }
  }

  /// Delete rental item
  Future<void> deleteRentalItem(String id) async {
    try {
      // Get item to delete images from Cloudinary
      final item = await getRentalItem(id);
      if (item != null) {
        for (final imageUrl in item.imageUrls) {
          await _cloudinaryService.deleteImage(imageUrl);
        }
      }

      // Delete document
      await _firestore.collection('rental_items').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete rental item: $e');
    }
  }

  // ========== Rental Request Operations ==========

  /// Create rental request
  Future<String> createRentalRequest(RentalRequestModel request) async {
    try {
      final docRef = await _firestore.collection('rental_requests').add(
            request.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create rental request: $e');
    }
  }

  /// Get rental request by ID
  Future<RentalRequestModel?> getRentalRequest(String id) async {
    try {
      final doc = await _firestore.collection('rental_requests').doc(id).get();
      if (doc.exists) {
        return RentalRequestModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting rental request: $e');
      return null;
    }
  }

  /// Get user's rental requests
  Stream<List<RentalRequestModel>> getUserRentalRequests(String userId) {
    return _firestore
        .collection('rental_requests')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Get all rental requests
  Stream<List<RentalRequestModel>> getRentalRequests({
    String? category,
    int limit = 100,
  }) {
    Query query = _firestore.collection('rental_requests');

    // Default: don't show hidden or fulfilled requests in general feed
    query = query.where('status', isEqualTo: 'active');

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      var requests = snapshot.docs.map((doc) => RentalRequestModel.fromFirestore(doc)).toList();
      
      if (category != null && category.isNotEmpty) {
        requests = requests.where((req) => req.category == category).toList();
      }
      
      return requests;
    });
  }

  /// Update rental request
  Future<void> updateRentalRequest(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('rental_requests').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update rental request: $e');
    }
  }

  /// Delete rental request
  Future<void> deleteRentalRequest(String id) async {
    try {
      await _firestore.collection('rental_requests').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete rental request: $e');
    }
  }

  // ========== Offer Operations ==========

  /// Create offer
  Future<String> createOffer(OfferModel offer) async {
    try {
      final docRef = await _firestore.collection('offers').add(
            offer.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create offer: $e');
    }
  }

  /// Get offers for a request
  Stream<List<OfferModel>> getRequestOffers(String requestId) {
    return _firestore
        .collection('offers')
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList());
  }

  /// Search rental items
  Future<List<RentalItemModel>> searchRentalItems(String query) async {
    try {
      final snapshot = await _firestore
          .collection('rental_items')
          .where('status', isEqualTo: 'available')
          .get();

      final allItems = snapshot.docs
          .map((doc) => RentalItemModel.fromFirestore(doc))
          .toList();

      // Filter by item name containing query (case insensitive)
      return allItems
          .where((item) =>
              item.itemName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching rental items: $e');
      return [];
    }
  }

  // ========== Chat Operations ==========

  /// Send message to chat
  Future<void> sendMessage(ChatMessageModel message) async {
    try {
      // Add message to messages collection
      await _firestore.collection('messages').add(
            message.toFirestore(),
          );

      // Get chat to find other participants
      final chatDoc = await _firestore.collection('chats').doc(message.chatId).get();
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);

      // Build unread increment for all participants except sender
      final unreadUpdates = <String, dynamic>{};
      for (final uid in participants) {
        if (uid != message.senderId) {
          unreadUpdates['unreadCount.$uid'] = FieldValue.increment(1);
        }
      }

      // Update chat with last message + unread counts
      await _firestore.collection('chats').doc(message.chatId).update({
        'lastMessage': message.message.isEmpty ? '📷 Image' : message.message,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        ...unreadUpdates,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark all messages in a chat as read for a user (reset unread count)
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      // Silently fail — not critical
    }
  }

  /// Stream of total unread message count across all chats for a user
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unread = data['unreadCount'];
        if (unread != null && unread is Map && unread[userId] != null) {
          total += (unread[userId] as num).toInt();
        }
      }
      return total;
    });
  }

  /// Get messages for a chat
  Stream<List<ChatMessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  /// Create or get chat between two users
  Future<String> getOrCreateChat(
    String userId1,
    String userId2, {
    String? rentalItemId,
    String? rentalItemName,
    String? rentalRequestId,
    String? rentalRequestName,
  }) async {
    try {
      // Check if chat already exists between THESE TWO users
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in existingChats.docs) {
        final chatData = doc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        if (participants.contains(userId2)) {
          // If this is an old chat missing rental info, patch it!
          final updates = <String, dynamic>{};
          
          if (rentalItemId != null && chatData['rentalItemId'] == null) {
            updates['rentalItemId'] = rentalItemId;
            updates['rentalItemName'] = rentalItemName;
          }
          
          if (rentalRequestId != null && chatData['rentalRequestId'] == null) {
            updates['rentalRequestId'] = rentalRequestId;
            updates['rentalRequestName'] = rentalRequestName;
          }
          
          if (updates.isNotEmpty) {
            await _firestore.collection('chats').doc(doc.id).update(updates);
          }
          return doc.id;
        }
      }

      // Create new chat
      final chat = ChatModel(
        id: '',
        participants: [userId1, userId2],
        rentalItemId: rentalItemId,
        rentalItemName: rentalItemName,
        rentalRequestId: rentalRequestId,
        rentalRequestName: rentalRequestName,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('chats').add(
            chat.toFirestore(),
          );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList());
  }

  /// Delete a chat and all its messages
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in this chat
      final messages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .get();
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      // Delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  /// Send a status/system message to a chat
  Future<void> sendSystemMessage(String chatId, String text, {String? contractId}) async {
    final message = ChatMessageModel(
      id: '',
      chatId: chatId,
      senderId: 'system',
      message: text,
      timestamp: DateTime.now(),
      messageType: 'status',
      contractId: contractId,
    );
    await sendMessage(message);
  }

  // ========== Contract Operations ==========

  /// Update the status of a contract message
  Future<void> updateMessageContractStatus(String chatId, String messageId, String status) async {
    try {
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({'contractStatus': status});
    } catch (e) {
      throw Exception('Failed to update contract status: $e');
    }
  }

  /// Confirm a contract from a chat message and create the actual contract document
  Future<void> confirmContract(String chatId, ChatMessageModel message, String currentUserId, String renterSignatureUrl) async {
    try {
      final contractData = message.contractData;
      if (contractData == null) throw Exception('No contract data found in message');

      final itemId = contractData['rentalItemId'] as String? ?? '';
      final ownerSignatureUrl = contractData['ownerSignatureUrl'] as String?;
      if (ownerSignatureUrl == null || ownerSignatureUrl.isEmpty) {
        throw Exception('ไม่พบลายเซ็นของผู้ให้เช่าในข้อมูลสัญญา');
      }
      
      // 1. Update message status in chat
      await _firestore
          .collection('messages')
          .doc(message.id)
          .update({'contractStatus': 'accepted'});

      // 2. Get Chat details to determine roles
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Chat not found');
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);

      String ownerId = '';
      String renterId = '';
      String itemName = contractData['rentalItemName'] ?? '';
      String condition = 'Good'; // Default
      double dailyRate = 0.0;

      // 3. Determine roles (Owner vs Renter)
      if (itemId.isNotEmpty) {
        // CASE A: Item-based rental
        final item = await getRentalItem(itemId);
        if (item == null) throw Exception('Rental item not found');
        
        ownerId = item.ownerId;
        renterId = participants.firstWhere((id) => id != ownerId, orElse: () => '');
        itemName = item.itemName;
        condition = item.condition;
        dailyRate = item.dailyRate;
      } else {
        // CASE B: Request-based rental
        final requestId = chatData['rentalRequestId'] as String?;
        if (requestId == null || requestId.isEmpty) {
          throw Exception('No item ID or request ID found for this contract');
        }

        final request = await getRentalRequest(requestId);
        if (request == null) throw Exception('Rental request not found');

        // The person who requested is the RENTER
        renterId = request.requesterId;
        // The other person in the chat is the OWNER (the one who fulfilled the request)
        ownerId = participants.firstWhere((id) => id != renterId, orElse: () => '');
        
        dailyRate = (contractData['totalPrice'] as num? ?? 0) / 
                    (DateTime.tryParse(contractData['endDate'] ?? '')?.difference(DateTime.tryParse(contractData['startDate'] ?? '') ?? DateTime.now()).inDays ?? 1).toDouble();
      }
      
      if (renterId.isEmpty || ownerId.isEmpty) throw Exception('Could not determine roles for contract');

      // 4. Get user names for the contract
      final owner = await getUser(ownerId);
      final renter = await getUser(renterId);

      if (owner == null) throw Exception('Owner data not found');
      if (renter == null) throw Exception('Renter data not found');

      // 5. Create the contract object
      final contract = RentalContractModel(
        id: '', // Will be auto-generated by .add()
        chatId: chatId,
        rentalItemId: itemId,
        itemName: itemName,
        ownerId: ownerId,
        ownerName: owner.fullName,
        renterId: renterId,
        renterName: renter.fullName,
        ownerSignatureUrl: ownerSignatureUrl,
        renterSignatureUrl: renterSignatureUrl,
        startDate: DateTime.tryParse(contractData['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(contractData['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 1)),
        dailyRate: dailyRate,
        totalAmount: (contractData['totalPrice'] as num?)?.toDouble() ?? 0.0,
        deposit: (contractData['deposit'] as num?)?.toDouble() ?? 0.0,
        condition: condition,
        createdAt: DateTime.now(),
      );

      // 6. Save contract to Firestore
      final contractId = await createContract(contract);

      // 7. Send initial status message to chat
      await sendSystemMessage(
        chatId,
        '✅ ผู้เช่าเซ็นสัญญาและยอมรับข้อเสนอแล้ว',
        contractId: contractId,
      );

      // 8. Update item status to 'rented' if applicable
      if (itemId.isNotEmpty) {
        await updateRentalItem(itemId, {'status': 'rented'});
      }
      
    } catch (e) {
      print('Error confirming contract: $e');
      throw Exception('Failed to confirm contract: $e');
    }
  }

  /// Create rental contract
  Future<String> createContract(RentalContractModel contract) async {
    try {
      final docRef = await _firestore.collection('contracts').add(
            contract.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create contract: $e');
    }
  }

  /// Get contract by ID
  Future<RentalContractModel?> getContract(String id) async {
    try {
      final doc = await _firestore.collection('contracts').doc(id).get();
      if (doc.exists) {
        return RentalContractModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting contract: $e');
      return null;
    }
  }

  /// Get user's contracts (as owner or renter)
  Stream<List<RentalContractModel>> getUserContracts(String userId) {
    return _firestore
        .collection('contracts')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RentalContractModel.fromFirestore(doc))
              .where((c) => c.ownerId == userId || c.renterId == userId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
  }

  /// Update contract (for GPS confirmation and status updates)
  Future<void> updateContract(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('contracts').doc(id).update(data);

      // Check if the contract was just completed
      if (data.containsKey('returnConfirmedAt')) {
        final contract = await getContract(id);
        if (contract != null) {
          // Both parties (owner and renter) become verified after completing one contract
          await _verifyUserAfterContract(contract.ownerId);
          await _verifyUserAfterContract(contract.renterId);
        }
      }
    } catch (e) {
      throw Exception('Failed to update contract: $e');
    }
  }

  /// Sync and update user verification based on past completed contracts
  Future<void> syncUserVerificationStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final bool currentlyVerified = userData['isVerified'] ?? false;

      // Query for completed contracts where user was either owner or renter
      final ownerContracts = await _firestore
          .collection('contracts')
          .where('ownerId', isEqualTo: userId)
          .where('returnConfirmedAt', isNull: false)
          .get();

      final renterContracts = await _firestore
          .collection('contracts')
          .where('renterId', isEqualTo: userId)
          .where('returnConfirmedAt', isNull: false)
          .get();

      final totalCompleted = ownerContracts.docs.length + renterContracts.docs.length;

      // If they have completed contracts but status is incorrect, sync it!
      if (totalCompleted > 0 || currentlyVerified != (totalCompleted > 0)) {
        await _firestore.collection('users').doc(userId).update({
          'isVerified': totalCompleted > 0,
          'totalRentals': totalCompleted,
        });
      }
    } catch (e) {
      print('Error syncing verification status: $e');
    }
  }

  /// Helper to verify user and increment rental count
  Future<void> _verifyUserAfterContract(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'totalRentals': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error verifying user $userId: $e');
    }
  }

  // ========== Review Operations ==========

  /// Create review
  Future<String> createReview(ReviewModel review) async {
    try {
      final docRef = await _firestore.collection('reviews').add(
            review.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// Get reviews for a user (as reviewee)
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  /// Check if user already reviewed a contract
  Future<bool> hasUserReviewedContract(String contractId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('contractId', isEqualTo: contractId)
          .where('reviewerId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking review: $e');
      return false;
    }
  }

  /// Update user rating based on all reviews
  Future<void> updateUserRating(String userId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: userId)
          .get();

      if (reviews.docs.isEmpty) return;

      final totalRating = reviews.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['rating'] ?? 0),
      );
      final avgRating = totalRating / reviews.docs.length;

      await _firestore.collection('users').doc(userId).update({
        'rating': avgRating,
        'totalReviews': reviews.docs.length,
      });
    } catch (e) {
      print('Error updating user rating: $e');
    }
  }

  // ========== Safety & Reports ==========

  /// Report a user
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String details,
  }) async {
    final docRef = _firestore.collection('reports').doc();
    await docRef.set({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'type': 'user',
    });
  }

  /// Report a rental item
  Future<void> reportItem({
    required String reporterId,
    required String reportedItemId,
    required String reason,
    required String details,
  }) async {
    final docRef = _firestore.collection('reports').doc();
    await docRef.set({
      'reporterId': reporterId,
      'reportedItemId': reportedItemId,
      'reason': reason,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'type': 'item',
    });
  }

  /// Block a user
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUids': FieldValue.arrayUnion([targetUserId]),
    });
  }

  /// Unblock a user
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUids': FieldValue.arrayRemove([targetUserId]),
    });
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    if (!doc.exists) return false;
    final blockedUids = List<String>.from(doc.data()?['blockedUids'] ?? []);
    return blockedUids.contains(targetUserId);
  }
}
