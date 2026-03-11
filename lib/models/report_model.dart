import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? reportedItemId;
  final String? reportedContractId;
  final String reason;
  final String details;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  ReportModel({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.reportedItemId,
    this.reportedContractId,
    required this.reason,
    required this.details,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedItemId': reportedItemId,
      'reportedContractId': reportedContractId,
      'reason': reason,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'],
      reportedItemId: data['reportedItemId'],
      reportedContractId: data['reportedContractId'],
      reason: data['reason'] ?? '',
      details: data['details'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}
