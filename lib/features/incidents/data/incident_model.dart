import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.details,
    required this.geopoint,
    required this.geohash,
    required this.status,
    required this.urgency,
    required this.createdAt,
    required this.enrichmentComplete,
    required this.followerCount,
  });

  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> details;
  final GeoPoint geopoint;
  final String geohash;
  final String status;
  final String urgency;
  final DateTime createdAt;
  final bool enrichmentComplete;
  final int followerCount;

  double get latitude => geopoint.latitude;
  double get longitude => geopoint.longitude;

  // Compatibility getters deliberately return no private information.
  String get userId => '';
  String get reporterName => '';
  String get reporterTel => '';
  List<String> get imageUrls => const [];
  List<String> get followers => const [];

  factory IncidentModel.fromMap(
    Map<String, dynamic> map, {
    required String docId,
  }) {
    final position = Map<String, dynamic>.from(
      map['position'] as Map? ?? const {},
    );
    final point = position['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);
    final summary = map['public_summary']?.toString() ?? '';
    return IncidentModel(
      id: docId,
      title: map['title']?.toString() ?? 'Emergency report',
      type: map['incident_type']?.toString() ?? 'unclassified',
      details: summary.isEmpty ? const {} : {'summary': summary},
      geopoint: point,
      geohash: position['geohash']?.toString() ?? '',
      status: normalizeIncidentStatus(map['status']),
      urgency: map['urgency']?.toString() ?? 'unknown',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      enrichmentComplete: map['enrichment_complete'] == true,
      followerCount: (map['follower_count'] as num?)?.toInt() ?? 0,
    );
  }

  static String normalizeIncidentStatus(Object? value) {
    final status = value?.toString().trim().toLowerCase().replaceAll(' ', '_');
    return switch (status) {
      'acknowledged' || 'accepted' => 'assigned',
      'inprogress' => 'in_progress',
      'complete' || 'completed' => 'resolved',
      'canceled' => 'cancelled',
      'pending' ||
      'assigned' ||
      'in_progress' ||
      'resolved' ||
      'cancelled' => status!,
      _ => 'pending',
    };
  }
}
