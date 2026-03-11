import 'package:cloud_firestore/cloud_firestore.dart';

class RentalContractModel {
  final String id;
  final String chatId;
  final String rentalItemId;
  final String itemName;
  final String ownerId;
  final String ownerName;
  final String renterId;
  final String renterName;
  final String? ownerSignatureUrl;
  final String? renterSignatureUrl;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyRate;
  final double totalAmount;
  final double deposit;
  final String condition;
  final String? ownerNotes;
  
  // Payment
  final String? paymentSlipUrl;
  final String paymentStatus; // 'pending', 'paid'
  final DateTime? paymentConfirmedAt;

  // Pickup Evidence
  final GeoPoint? ownerPickupLocation;
  final GeoPoint? renterPickupLocation;
  final String? ownerPickupPhotoUrl;
  final String? renterPickupPhotoUrl;
  final DateTime? pickupConfirmedAt;
  final bool ownerPickupConfirmed;
  final bool renterPickupConfirmed;

  // Return Evidence
  final GeoPoint? ownerReturnLocation;
  final GeoPoint? renterReturnLocation;
  final String? ownerReturnPhotoUrl;
  final String? renterReturnPhotoUrl;
  final DateTime? returnConfirmedAt;
  final bool ownerReturnConfirmed;
  final bool renterReturnConfirmed;

  final DateTime createdAt;

  RentalContractModel({
    required this.id,
    required this.chatId,
    required this.rentalItemId,
    required this.itemName,
    required this.ownerId,
    required this.ownerName,
    required this.renterId,
    required this.renterName,
    this.ownerSignatureUrl,
    this.renterSignatureUrl,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    required this.totalAmount,
    required this.deposit,
    required this.condition,
    this.ownerNotes,
    this.paymentSlipUrl,
    this.paymentStatus = 'pending',
    this.paymentConfirmedAt,
    this.ownerPickupLocation,
    this.renterPickupLocation,
    this.ownerPickupPhotoUrl,
    this.renterPickupPhotoUrl,
    this.pickupConfirmedAt,
    this.ownerPickupConfirmed = false,
    this.renterPickupConfirmed = false,
    this.ownerReturnLocation,
    this.renterReturnLocation,
    this.ownerReturnPhotoUrl,
    this.renterReturnPhotoUrl,
    this.returnConfirmedAt,
    this.ownerReturnConfirmed = false,
    this.renterReturnConfirmed = false,
    required this.createdAt,
  });

  bool get isPickupComplete => ownerPickupConfirmed && renterPickupConfirmed;
  bool get isReturnComplete => ownerReturnConfirmed && renterReturnConfirmed;
  bool get isSigned => ownerSignatureUrl != null && renterSignatureUrl != null;

  /// Calculate rental duration in days
  int get rentalDays => endDate.difference(startDate).inDays + 1;

  factory RentalContractModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalContractModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      rentalItemId: data['rentalItemId'] ?? '',
      itemName: data['itemName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      renterId: data['renterId'] ?? '',
      renterName: data['renterName'] ?? '',
      ownerSignatureUrl: data['ownerSignatureUrl'],
      renterSignatureUrl: data['renterSignatureUrl'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      dailyRate: (data['dailyRate'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),
      condition: data['condition'] ?? '',
      ownerNotes: data['ownerNotes'],
      paymentSlipUrl: data['paymentSlipUrl'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentConfirmedAt: data['paymentConfirmedAt'] != null
          ? (data['paymentConfirmedAt'] as Timestamp).toDate()
          : null,
      ownerPickupLocation: data['ownerPickupLocation'] as GeoPoint?,
      renterPickupLocation: data['renterPickupLocation'] as GeoPoint?,
      ownerPickupPhotoUrl: data['ownerPickupPhotoUrl'],
      renterPickupPhotoUrl: data['renterPickupPhotoUrl'],
      pickupConfirmedAt: data['pickupConfirmedAt'] != null
          ? (data['pickupConfirmedAt'] as Timestamp).toDate()
          : null,
      ownerPickupConfirmed: data['ownerPickupConfirmed'] ?? false,
      renterPickupConfirmed: data['renterPickupConfirmed'] ?? false,
      ownerReturnLocation: data['ownerReturnLocation'] as GeoPoint?,
      renterReturnLocation: data['renterReturnLocation'] as GeoPoint?,
      ownerReturnPhotoUrl: data['ownerReturnPhotoUrl'],
      renterReturnPhotoUrl: data['renterReturnPhotoUrl'],
      returnConfirmedAt: data['returnConfirmedAt'] != null
          ? (data['returnConfirmedAt'] as Timestamp).toDate()
          : null,
      ownerReturnConfirmed: data['ownerReturnConfirmed'] ?? false,
      renterReturnConfirmed: data['renterReturnConfirmed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'rentalItemId': rentalItemId,
      'itemName': itemName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'renterId': renterId,
      'renterName': renterName,
      'ownerSignatureUrl': ownerSignatureUrl,
      'renterSignatureUrl': renterSignatureUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'dailyRate': dailyRate,
      'totalAmount': totalAmount,
      'deposit': deposit,
      'condition': condition,
      'ownerNotes': ownerNotes,
      'paymentSlipUrl': paymentSlipUrl,
      'paymentStatus': paymentStatus,
      'paymentConfirmedAt': paymentConfirmedAt != null
          ? Timestamp.fromDate(paymentConfirmedAt!)
          : null,
      'ownerPickupLocation': ownerPickupLocation,
      'renterPickupLocation': renterPickupLocation,
      'ownerPickupPhotoUrl': ownerPickupPhotoUrl,
      'renterPickupPhotoUrl': renterPickupPhotoUrl,
      'pickupConfirmedAt': pickupConfirmedAt != null
          ? Timestamp.fromDate(pickupConfirmedAt!)
          : null,
      'ownerPickupConfirmed': ownerPickupConfirmed,
      'renterPickupConfirmed': renterPickupConfirmed,
      'ownerReturnLocation': ownerReturnLocation,
      'renterReturnLocation': renterReturnLocation,
      'ownerReturnPhotoUrl': ownerReturnPhotoUrl,
      'renterReturnPhotoUrl': renterReturnPhotoUrl,
      'returnConfirmedAt': returnConfirmedAt != null
          ? Timestamp.fromDate(returnConfirmedAt!)
          : null,
      'ownerReturnConfirmed': ownerReturnConfirmed,
      'renterReturnConfirmed': renterReturnConfirmed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalContractModel copyWith({
    String? id,
    String? chatId,
    String? rentalItemId,
    String? itemName,
    String? ownerId,
    String? ownerName,
    String? renterId,
    String? renterName,
    String? ownerSignatureUrl,
    String? renterSignatureUrl,
    DateTime? startDate,
    DateTime? endDate,
    double? dailyRate,
    double? totalAmount,
    double? deposit,
    String? condition,
    String? ownerNotes,
    String? paymentSlipUrl,
    String? paymentStatus,
    DateTime? paymentConfirmedAt,
    GeoPoint? ownerPickupLocation,
    GeoPoint? renterPickupLocation,
    String? ownerPickupPhotoUrl,
    String? renterPickupPhotoUrl,
    DateTime? pickupConfirmedAt,
    bool? ownerPickupConfirmed,
    bool? renterPickupConfirmed,
    GeoPoint? ownerReturnLocation,
    GeoPoint? renterReturnLocation,
    String? ownerReturnPhotoUrl,
    String? renterReturnPhotoUrl,
    DateTime? returnConfirmedAt,
    bool? ownerReturnConfirmed,
    bool? renterReturnConfirmed,
    DateTime? createdAt,
  }) {
    return RentalContractModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      rentalItemId: rentalItemId ?? this.rentalItemId,
      itemName: itemName ?? this.itemName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      ownerSignatureUrl: ownerSignatureUrl ?? this.ownerSignatureUrl,
      renterSignatureUrl: renterSignatureUrl ?? this.renterSignatureUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyRate: dailyRate ?? this.dailyRate,
      totalAmount: totalAmount ?? this.totalAmount,
      deposit: deposit ?? this.deposit,
      condition: condition ?? this.condition,
      ownerNotes: ownerNotes ?? this.ownerNotes,
      paymentSlipUrl: paymentSlipUrl ?? this.paymentSlipUrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentConfirmedAt: paymentConfirmedAt ?? this.paymentConfirmedAt,
      ownerPickupLocation: ownerPickupLocation ?? this.ownerPickupLocation,
      renterPickupLocation: renterPickupLocation ?? this.renterPickupLocation,
      ownerPickupPhotoUrl: ownerPickupPhotoUrl ?? this.ownerPickupPhotoUrl,
      renterPickupPhotoUrl: renterPickupPhotoUrl ?? this.renterPickupPhotoUrl,
      pickupConfirmedAt: pickupConfirmedAt ?? this.pickupConfirmedAt,
      ownerPickupConfirmed: ownerPickupConfirmed ?? this.ownerPickupConfirmed,
      renterPickupConfirmed: renterPickupConfirmed ?? this.renterPickupConfirmed,
      ownerReturnLocation: ownerReturnLocation ?? this.ownerReturnLocation,
      renterReturnLocation: renterReturnLocation ?? this.renterReturnLocation,
      ownerReturnPhotoUrl: ownerReturnPhotoUrl ?? this.ownerReturnPhotoUrl,
      renterReturnPhotoUrl: renterReturnPhotoUrl ?? this.renterReturnPhotoUrl,
      returnConfirmedAt: returnConfirmedAt ?? this.returnConfirmedAt,
      ownerReturnConfirmed: ownerReturnConfirmed ?? this.ownerReturnConfirmed,
      renterReturnConfirmed: renterReturnConfirmed ?? this.renterReturnConfirmed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
