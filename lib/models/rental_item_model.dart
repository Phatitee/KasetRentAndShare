import 'package:cloud_firestore/cloud_firestore.dart';

class RentalItemModel {
  final String id;
  final String ownerId;
  final String itemName;
  final String category;
  final String condition; // "Like New (95%+)", "Good", "Fair"
  final double dailyRate;
  final double deposit;
  final String description;
  final List<String> imageUrls;
  final String status; // "available", "pending", "rented"
  final DateTime? rentedStartDate;
  final DateTime? rentedEndDate;
  final String? rentedToUserId;
  final String? rentedToUserName;
  final DateTime createdAt;

  RentalItemModel({
    required this.id,
    required this.ownerId,
    required this.itemName,
    required this.category,
    required this.condition,
    required this.dailyRate,
    required this.deposit,
    required this.description,
    required this.imageUrls,
    this.status = 'available',
    this.rentedStartDate,
    this.rentedEndDate,
    this.rentedToUserId,
    this.rentedToUserName,
    required this.createdAt,
  });

  factory RentalItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalItemModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      itemName: data['itemName'] ?? '',
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      dailyRate: (data['dailyRate'] ?? 0.0).toDouble(),
      deposit: (data['deposit'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'available',
      rentedStartDate: data['rentedStartDate'] != null
          ? (data['rentedStartDate'] as Timestamp).toDate()
          : null,
      rentedEndDate: data['rentedEndDate'] != null
          ? (data['rentedEndDate'] as Timestamp).toDate()
          : null,
      rentedToUserId: data['rentedToUserId'],
      rentedToUserName: data['rentedToUserName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'itemName': itemName,
      'category': category,
      'condition': condition,
      'dailyRate': dailyRate,
      'deposit': deposit,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'rentedStartDate':
          rentedStartDate != null ? Timestamp.fromDate(rentedStartDate!) : null,
      'rentedEndDate':
          rentedEndDate != null ? Timestamp.fromDate(rentedEndDate!) : null,
      'rentedToUserId': rentedToUserId,
      'rentedToUserName': rentedToUserName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalItemModel copyWith({
    String? id,
    String? ownerId,
    String? itemName,
    String? category,
    String? condition,
    double? dailyRate,
    double? deposit,
    String? description,
    List<String>? imageUrls,
    String? status,
    DateTime? rentedStartDate,
    DateTime? rentedEndDate,
    String? rentedToUserId,
    String? rentedToUserName,
    DateTime? createdAt,
  }) {
    return RentalItemModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      dailyRate: dailyRate ?? this.dailyRate,
      deposit: deposit ?? this.deposit,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      rentedStartDate: rentedStartDate ?? this.rentedStartDate,
      rentedEndDate: rentedEndDate ?? this.rentedEndDate,
      rentedToUserId: rentedToUserId ?? this.rentedToUserId,
      rentedToUserName: rentedToUserName ?? this.rentedToUserName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
