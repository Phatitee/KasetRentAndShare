import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequestModel {
  final String id;
  final String requesterId;
  final String category;
  final String itemDescription;
  final double estimatedBudget;
  final DateTime startDate;
  final DateTime endDate;
  final String additionalDetails;
  final String status; // active, fulfilled, cancelled
  final DateTime createdAt;

  RentalRequestModel({
    required this.id,
    required this.requesterId,
    required this.category,
    required this.itemDescription,
    required this.estimatedBudget,
    required this.startDate,
    required this.endDate,
    this.additionalDetails = '',
    this.status = 'active',
    required this.createdAt,
  });

  /// Get total duration of rental in days
  int get rentalDurationDays => endDate.difference(startDate).inDays + 1;

  factory RentalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalRequestModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      category: data['category'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      estimatedBudget: (data['estimatedBudget'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      additionalDetails: data['additionalDetails'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'category': category,
      'itemDescription': itemDescription,
      'estimatedBudget': estimatedBudget,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'additionalDetails': additionalDetails,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalRequestModel copyWith({
    String? id,
    String? requesterId,
    String? category,
    String? itemDescription,
    double? estimatedBudget,
    DateTime? startDate,
    DateTime? endDate,
    String? additionalDetails,
    String? status,
    DateTime? createdAt,
  }) {
    return RentalRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      category: category ?? this.category,
      itemDescription: itemDescription ?? this.itemDescription,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
