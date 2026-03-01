import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String userId;
  final String reporterName;
  final String reporterTel;
  final String title;
  final String type;
  final Map<String, dynamic> details;
  final GeoPoint geopoint;
  final String geohash;
  final double latitude;
  final double longitude;
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
    required this.geopoint,
    required this.geohash,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.urgency,
    required this.createdAt,
    required this.imageUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'reporter_name': reporterName,
      'reporter_tel': reporterTel,
      'title': title,
      'incident_type': type,
      'description': jsonEncode(details),
      'position': {
        'geohash': geohash,
        'geopoint': geopoint,
      },
      'latitude': latitude,
      'longitude': longitude,

      'status': status,
      'urgency': urgency,
      'created_at': Timestamp.fromDate(createdAt),
      'image_urls': imageUrls,
    };
  }

  factory IncidentModel.fromMap(
    Map<String, dynamic> map, {
    required String docId,
  }) {
    final position = map['position'] as Map<String, dynamic>?;

    final GeoPoint geopoint =
        position?['geopoint'] ?? const GeoPoint(0, 0);

    return IncidentModel(
      id: docId,
      userId: map['user_id'] ?? '',
      reporterName: map['reporter_name'] ?? '',
      reporterTel: map['reporter_tel'] ?? '',
      title: map['title'] ?? '',
      type: map['incident_type'] ?? 'General',
      details: map['description'] != null
          ? jsonDecode(map['description'])
          : {},
      geopoint: geopoint,
      geohash: position?['geohash'] ?? '',
      latitude: geopoint.latitude,
      longitude: geopoint.longitude,
      status: map['status'] ?? 'Pending',
      urgency: map['urgency'] ?? 'ทั่วไป',
      createdAt:
          (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(map['image_urls'] ?? []),
    );
  }
}