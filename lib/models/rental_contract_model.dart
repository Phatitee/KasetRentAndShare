import 'package:cloud_firestore/cloud_firestore.dart';

class RentalContractModel {
  final String id;
  final String rentalItemId;
  final String itemName;
  final String ownerId;
  final String ownerName;
  final String renterId;
  final String renterName;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyRate;
  final double totalAmount;
  final double deposit;
  final String condition;
  final String? ownerNotes;
  final GeoPoint? pickupLocation;
  final String? pickupLocationName;
  final GeoPoint? returnLocation;
  final String? returnLocationName;
  final DateTime? pickupConfirmedAt;
  final DateTime? returnConfirmedAt;
  final bool ownerPickupConfirmed;
  final bool renterPickupConfirmed;
  final bool ownerReturnConfirmed;
  final bool renterReturnConfirmed;
  final String status; // pending, active, completed, disputed
  final DateTime createdAt;

  RentalContractModel({
    required this.id,
    required this.rentalItemId,
    required this.itemName,
    required this.ownerId,
    required this.ownerName,
    required this.renterId,
    required this.renterName,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    required this.totalAmount,
    required this.deposit,
    required this.condition,
    this.ownerNotes,
    this.pickupLocation,
    this.pickupLocationName,
    this.returnLocation,
    this.returnLocationName,
    this.pickupConfirmedAt,
    this.returnConfirmedAt,
    this.ownerPickupConfirmed = false,
    this.renterPickupConfirmed = false,
    this.ownerReturnConfirmed = false,
    this.renterReturnConfirmed = false,
    this.status = 'pending',
    required this.createdAt,
  });

  /// Calculate rental duration in days
  int get rentalDays => endDate.difference(startDate).inDays + 1;

  /// Check if both parties confirmed pickup
  bool get isPickupComplete => ownerPickupConfirmed && renterPickupConfirmed;

  /// Check if both parties confirmed return
  bool get isReturnComplete => ownerReturnConfirmed && renterReturnConfirmed;

  factory RentalContractModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalContractModel(
      id: doc.id,
      rentalItemId: data['rentalItemId'] ?? '',
      itemName: data['itemName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      renterId: data['renterId'] ?? '',
      renterName: data['renterName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      dailyRate: (data['dailyRate'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),
      condition: data['condition'] ?? '',
      ownerNotes: data['ownerNotes'],
      pickupLocation: data['pickupLocation'] as GeoPoint?,
      pickupLocationName: data['pickupLocationName'],
      returnLocation: data['returnLocation'] as GeoPoint?,
      returnLocationName: data['returnLocationName'],
      pickupConfirmedAt: data['pickupConfirmedAt'] != null
          ? (data['pickupConfirmedAt'] as Timestamp).toDate()
          : null,
      returnConfirmedAt: data['returnConfirmedAt'] != null
          ? (data['returnConfirmedAt'] as Timestamp).toDate()
          : null,
      ownerPickupConfirmed: data['ownerPickupConfirmed'] ?? false,
      renterPickupConfirmed: data['renterPickupConfirmed'] ?? false,
      ownerReturnConfirmed: data['ownerReturnConfirmed'] ?? false,
      renterReturnConfirmed: data['renterReturnConfirmed'] ?? false,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rentalItemId': rentalItemId,
      'itemName': itemName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'renterId': renterId,
      'renterName': renterName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'dailyRate': dailyRate,
      'totalAmount': totalAmount,
      'deposit': deposit,
      'condition': condition,
      'ownerNotes': ownerNotes,
      'pickupLocation': pickupLocation,
      'pickupLocationName': pickupLocationName,
      'returnLocation': returnLocation,
      'returnLocationName': returnLocationName,
      'pickupConfirmedAt': pickupConfirmedAt != null
          ? Timestamp.fromDate(pickupConfirmedAt!)
          : null,
      'returnConfirmedAt': returnConfirmedAt != null
          ? Timestamp.fromDate(returnConfirmedAt!)
          : null,
      'ownerPickupConfirmed': ownerPickupConfirmed,
      'renterPickupConfirmed': renterPickupConfirmed,
      'ownerReturnConfirmed': ownerReturnConfirmed,
      'renterReturnConfirmed': renterReturnConfirmed,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalContractModel copyWith({
    String? id,
    String? rentalItemId,
    String? itemName,
    String? ownerId,
    String? ownerName,
    String? renterId,
    String? renterName,
    DateTime? startDate,
    DateTime? endDate,
    double? dailyRate,
    double? totalAmount,
    double? deposit,
    String? condition,
    String? ownerNotes,
    GeoPoint? pickupLocation,
    String? pickupLocationName,
    GeoPoint? returnLocation,
    String? returnLocationName,
    DateTime? pickupConfirmedAt,
    DateTime? returnConfirmedAt,
    bool? ownerPickupConfirmed,
    bool? renterPickupConfirmed,
    bool? ownerReturnConfirmed,
    bool? renterReturnConfirmed,
    String? status,
    DateTime? createdAt,
  }) {
    return RentalContractModel(
      id: id ?? this.id,
      rentalItemId: rentalItemId ?? this.rentalItemId,
      itemName: itemName ?? this.itemName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyRate: dailyRate ?? this.dailyRate,
      totalAmount: totalAmount ?? this.totalAmount,
      deposit: deposit ?? this.deposit,
      condition: condition ?? this.condition,
      ownerNotes: ownerNotes ?? this.ownerNotes,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLocationName: pickupLocationName ?? this.pickupLocationName,
      returnLocation: returnLocation ?? this.returnLocation,
      returnLocationName: returnLocationName ?? this.returnLocationName,
      pickupConfirmedAt: pickupConfirmedAt ?? this.pickupConfirmedAt,
      returnConfirmedAt: returnConfirmedAt ?? this.returnConfirmedAt,
      ownerPickupConfirmed: ownerPickupConfirmed ?? this.ownerPickupConfirmed,
      renterPickupConfirmed: renterPickupConfirmed ?? this.renterPickupConfirmed,
      ownerReturnConfirmed: ownerReturnConfirmed ?? this.ownerReturnConfirmed,
      renterReturnConfirmed: renterReturnConfirmed ?? this.renterReturnConfirmed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
