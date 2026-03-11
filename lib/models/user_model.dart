import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final double rating;
  final int totalRentals;
  final int totalReviews;
  final bool isVerified;
  final DateTime createdAt;
  
  // New safety field
  final List<String> blockedUids;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.rating = 0.0,
    this.totalRentals = 0,
    this.totalReviews = 0,
    this.isVerified = false,
    required this.createdAt,
    this.blockedUids = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRentals: data['totalRentals'] ?? 0,
      totalReviews: data['totalReviews'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      blockedUids: List<String>.from(data['blockedUids'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'rating': rating,
      'totalRentals': totalRentals,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'blockedUids': blockedUids,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    double? rating,
    int? totalRentals,
    int? totalReviews,
    bool? isVerified,
    DateTime? createdAt,
    List<String>? blockedUids,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalRentals: totalRentals ?? this.totalRentals,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      blockedUids: blockedUids ?? this.blockedUids,
    );
  }

  String get fullName => name;
}
