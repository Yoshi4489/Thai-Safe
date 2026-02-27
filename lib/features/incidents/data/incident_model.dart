import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String userId;       // 🆕 เพิ่ม: ID ผู้แจ้ง
  final String reporterName; // 🆕 เพิ่ม: ชื่อผู้แจ้ง
  final String reporterTel;  // 🆕 เพิ่ม: เบอร์โทรผู้แจ้ง
  final String title;
  final String type;
  final Map<String, dynamic> details;
  final double latitude;
  final double longitude;
  final String geohash;
  final String status;
  final String urgency;
  final DateTime createdAt;
  final List<String> imageUrls;

  IncidentModel({
    required this.id,
    required this.userId,
    required this.reporterName,
    required this.reporterTel,
    required this.title,
    required this.type,
    required this.details,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.status,
    required this.urgency,
    required this.createdAt,
    required this.imageUrls,
  });

  // แปลง Object -> Map (สำหรับบันทึกลง Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,           // 🆕
      'reporter_name': reporterName, // 🆕
      'reporter_tel': reporterTel,   // 🆕
      'title': title,
      'incident_type': type,
      'description': jsonEncode(details), 
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'status': status,
      'urgency': urgency,
      'created_at': Timestamp.fromDate(createdAt), 
      'image_urls': imageUrls, 
    };
  }

  // แปลง Map (จาก Firestore) -> Object
  factory IncidentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    Map<String, dynamic> parsedDetails = {};
    try {
      if (map['description'] != null) {
        parsedDetails = jsonDecode(map['description']) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error decoding details: $e");
    }

    return IncidentModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',             // 🆕
      reporterName: map['reporter_name'] ?? '', // 🆕
      reporterTel: map['reporter_tel'] ?? '',   // 🆕
      title: map['title'] ?? '',
      type: map['incident_type'] ?? 'General',
      details: parsedDetails,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: map['geohash'] ?? '',
      status: map['status'] ?? 'Pending',
      urgency: map['urgency'] ?? 'ทั่วไป',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(map['image_urls'] ?? []),
    );
  }
}