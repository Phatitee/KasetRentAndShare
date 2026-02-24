import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String requestId;
  final String offererId;
  final String offererName;
  final double offererRating;
  final String itemDescription;
  final double pricePerDay;
  final String condition;
  final String message;
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.requestId,
    required this.offererId,
    required this.offererName,
    this.offererRating = 0.0,
    required this.itemDescription,
    required this.pricePerDay,
    required this.condition,
    required this.message,
    required this.createdAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      offererId: data['offererId'] ?? '',
      offererName: data['offererName'] ?? '',
      offererRating: (data['offererRating'] ?? 0.0).toDouble(),
      itemDescription: data['itemDescription'] ?? '',
      pricePerDay: (data['pricePerDay'] ?? 0.0).toDouble(),
      condition: data['condition'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'offererId': offererId,
      'offererName': offererName,
      'offererRating': offererRating,
      'itemDescription': itemDescription,
      'pricePerDay': pricePerDay,
      'condition': condition,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
