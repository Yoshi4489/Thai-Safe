import 'package:cloud_firestore/cloud_firestore.dart';

enum RescueRequestStatus {
  pending,
  approved,
  rejected,
  expired,
  suspended,
  revoked,
}

class RescueRequestModel {
  const RescueRequestModel({
    required this.id,
    required this.userId,
    required this.organization,
    required this.identityNumberLast4,
    required this.evidencePaths,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.decisionReason,
  });

  final String id;
  final String userId;
  final String organization;
  final String identityNumberLast4;
  final List<String> evidencePaths;
  final RescueRequestStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? decisionReason;

  String get name => organization;
  String get phone => 'ID ending ••••$identityNumberLast4';

  factory RescueRequestModel.fromMap(Map<String, dynamic> map, String id) {
    final statusName = map['status']?.toString() ?? 'pending';
    return RescueRequestModel(
      id: id,
      userId: map['uid']?.toString() ?? id,
      organization: map['organization']?.toString() ?? 'Not specified',
      identityNumberLast4: map['identity_number_last4']?.toString() ?? '----',
      evidencePaths: List<String>.from(map['evidence_paths'] as List? ?? []),
      status: RescueRequestStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => RescueRequestStatus.pending,
      ),
      createdAt:
          (map['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: map['reviewed_by']?.toString(),
      reviewedAt: (map['reviewed_at'] as Timestamp?)?.toDate(),
      decisionReason: map['decision_reason']?.toString(),
    );
  }
}
