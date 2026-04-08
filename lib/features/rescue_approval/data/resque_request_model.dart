import 'package:cloud_firestore/cloud_firestore.dart';

enum RescueRequestStatus {
  pending,
  approved,
  rejected,
}

class RescueRequestModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final RescueRequestStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  RescueRequestModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory RescueRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RescueRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      status: RescueRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RescueRequestStatus.pending,
      ),
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      reviewedBy: map['reviewed_by'],
      reviewedAt: map['reviewed_at'] != null
          ? (map['reviewed_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'status': status.name,
      'created_at': createdAt,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt,
    };
  }

  RescueRequestModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    RescueRequestStatus? status,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return RescueRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
