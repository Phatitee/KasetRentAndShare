import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/rental_item_model.dart';
import '../models/rental_request_model.dart';
import '../models/offer_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../models/rental_contract_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== Storage Operations ==========

  /// Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final Reference ref = _storage.ref().child('$folder/$fileName');

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages(
      List<File> imageFiles, String folder) async {
    final List<String> downloadUrls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile, folder);
      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Failed to delete image: $e');
    }
  }

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
    int limit = 20,
  }) {
    Query query = _firestore.collection('rental_items');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => RentalItemModel.fromFirestore(doc)).toList());
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
      // Get item to delete images
      final item = await getRentalItem(id);
      if (item != null) {
        // Delete images from storage
        for (final imageUrl in item.imageUrls) {
          await deleteImage(imageUrl);
        }
      }

      // Delete document
      await _firestore.collection('rental_items').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete rental item: $e');
    }
  }

  // ========== User Operations ==========

  /// Get user data by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
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
    int limit = 20,
  }) {
    Query query = _firestore.collection('rental_requests');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RentalRequestModel.fromFirestore(doc))
        .toList());
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

      // Update chat with last message
      await _firestore.collection('chats').doc(message.chatId).update({
        'lastMessage': message.message.isEmpty ? '📷 Image' : message.message,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
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
  }) async {
    try {
      // Check if chat already exists
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in existingChats.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participants.contains(userId2)) {
          return doc.id;
        }
      }

      // Create new chat
      final chat = ChatModel(
        id: '',
        participants: [userId1, userId2],
        rentalItemId: rentalItemId,
        rentalItemName: rentalItemName,
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

  // ========== Contract Operations ==========

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
    // Get contracts where user is either owner or renter
    return _firestore
        .collection('contracts')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((ownerSnapshot) async {
      final renterSnapshot = await _firestore
          .collection('contracts')
          .where('renterId', isEqualTo: userId)
          .get();

      final allDocs = [...ownerSnapshot.docs, ...renterSnapshot.docs];
      
      // Remove duplicates
      final seen = <String>{};
      final uniqueDocs = allDocs.where((doc) => seen.add(doc.id)).toList();
      
      return uniqueDocs
          .map((doc) => RentalContractModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Update contract (for GPS confirmation)
  Future<void> updateContract(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('contracts').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update contract: $e');
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
}
