import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalProfileModel {
  final String user_id;
  final String blood_type;
  final String chronic_diseases;
  final String regular_medications;
  final String allergies;
  final List<Map<String, dynamic>> contact_list;
  final DateTime updated_at;

  MedicalProfileModel({
    required this.user_id,
    required this.blood_type,
    required this.chronic_diseases,
    required this.regular_medications,
    required this.allergies,
    required this.contact_list,
    required this.updated_at,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'blood_type': blood_type,
      'chronic_diseases': chronic_diseases,
      'regular_medications': regular_medications,
      'allergies': allergies,
      'contact_list': contact_list,
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  factory MedicalProfileModel.fromMap(Map<String, dynamic> map) {
    return MedicalProfileModel(
      user_id: map['user_id'],
      blood_type: map['blood_type'],
      chronic_diseases: map['chronic_diseases'],
      regular_medications: map['regular_medications'],
      allergies: map['allergies'],
      contact_list:
          (map['contact_list'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          [],
      updated_at: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  MedicalProfileModel copyWith({
    String? user_id,
    String? blood_type,
    String? chronic_diseases,
    String? regular_medications,
    String? allergies,
    List<Map<String, dynamic>>? contact_list,
    DateTime? updated_at,
  }) {
    return MedicalProfileModel(
      user_id: user_id ?? this.user_id,
      blood_type: blood_type ?? this.blood_type,
      chronic_diseases: chronic_diseases ?? this.chronic_diseases,
      regular_medications: regular_medications ?? this.regular_medications,
      allergies: allergies ?? this.allergies,
      contact_list: contact_list ?? this.contact_list,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
