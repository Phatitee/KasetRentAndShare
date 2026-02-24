import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String contractId;
  final String rentalItemId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String revieweeName;
  final String reviewType; // 'owner_to_renter' or 'renter_to_owner'
  final double rating;
  final String comment;
  final List<String> tags; // e.g., 'on_time', 'good_condition', 'friendly'
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.contractId,
    required this.rentalItemId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewType,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      contractId: data['contractId'] ?? '',
      rentalItemId: data['rentalItemId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      revieweeName: data['revieweeName'] ?? '',
      reviewType: data['reviewType'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contractId': contractId,
      'rentalItemId': rentalItemId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'revieweeName': revieweeName,
      'reviewType': reviewType,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
