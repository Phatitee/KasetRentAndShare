import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final bool isVerified; // ID card verified
  final String? idCardUrl;
  final String? faceImageUrl;
  final String? photoUrl; // Google profile photo
  final double rating;
  final int totalRentals;
  final int totalReviews;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.isVerified = false,
    this.idCardUrl,
    this.faceImageUrl,
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
      isVerified: data['isVerified'] ?? false,
      idCardUrl: data['idCardUrl'],
      faceImageUrl: data['faceImageUrl'],
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
      'isVerified': isVerified,
      'idCardUrl': idCardUrl,
      'faceImageUrl': faceImageUrl,
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
    bool? isVerified,
    String? idCardUrl,
    String? faceImageUrl,
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
      isVerified: isVerified ?? this.isVerified,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalRentals: totalRentals ?? this.totalRentals,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
