import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl; // Google profile photo
  final double rating;
  final int totalRentals;
  final int totalReviews;
  final DateTime createdAt;

  String get fullName => name;
  
  // Account is considered verified if registered with @ku.th email
  bool get isVerified => email.endsWith('@ku.th');

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.rating = 0.0,
    this.totalRentals = 0,
    this.totalReviews = 0,
    required this.createdAt,
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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
      'createdAt': Timestamp.fromDate(createdAt),
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
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalRentals: totalRentals ?? this.totalRentals,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
