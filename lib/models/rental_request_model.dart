import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequestModel {
  final String id;
  final String requesterId;
  final String itemDescription;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final double estimatedBudget;
  final GeoPoint pickupLocation;
  final String locationName;
  final String additionalDetails;
  final DateTime createdAt;

  RentalRequestModel({
    required this.id,
    required this.requesterId,
    required this.itemDescription,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.estimatedBudget,
    required this.pickupLocation,
    required this.locationName,
    this.additionalDetails = '',
    required this.createdAt,
  });

  factory RentalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalRequestModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      category: data['category'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      estimatedBudget: (data['estimatedBudget'] ?? 0.0).toDouble(),
      pickupLocation: data['pickupLocation'] as GeoPoint,
      locationName: data['locationName'] ?? '',
      additionalDetails: data['additionalDetails'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'itemDescription': itemDescription,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'estimatedBudget': estimatedBudget,
      'pickupLocation': pickupLocation,
      'locationName': locationName,
      'additionalDetails': additionalDetails,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get rentalDurationDays {
    return endDate.difference(startDate).inDays;
  }

  RentalRequestModel copyWith({
    String? id,
    String? requesterId,
    String? itemDescription,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? estimatedBudget,
    GeoPoint? pickupLocation,
    String? locationName,
    String? additionalDetails,
    DateTime? createdAt,
  }) {
    return RentalRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      itemDescription: itemDescription ?? this.itemDescription,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      locationName: locationName ?? this.locationName,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
