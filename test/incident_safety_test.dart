import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

void main() {
  group('quick SOS contract', () {
    test('preserves the idempotency key and GPS accuracy', () {
      const request = QuickIncidentRequest(
        clientRequestId: 'request-12345678',
        latitude: 13.7563,
        longitude: 100.5018,
        accuracyM: 8.5,
        lastKnownLatitude: 13.75,
        lastKnownLongitude: 100.5,
        medicalSummaryConsent: true,
      );
      final restored = QuickIncidentRequest.fromJson(request.toJson());
      expect(restored.clientRequestId, request.clientRequestId);
      expect(restored.accuracyM, 8.5);
      expect(restored.medicalSummaryConsent, isTrue);
    });
  });

  group('public incident privacy', () {
    test('normalizes legacy states during dual-read rollout', () {
      expect(IncidentModel.normalizeIncidentStatus('Acknowledged'), 'assigned');
      expect(
        IncidentModel.normalizeIncidentStatus('In Progress'),
        'in_progress',
      );
      expect(IncidentModel.normalizeIncidentStatus('Completed'), 'resolved');
    });

    test('does not deserialize legacy reporter or media fields', () {
      final incident = IncidentModel.fromMap({
        'title': 'Test incident',
        'status': 'Pending',
        'position': {
          'geohash': 'w4rqqq',
          'geopoint': const GeoPoint(13.76, 100.5),
        },
        'reporter_name': 'Must remain private',
        'reporter_tel': '0000000000',
        'image_urls': ['https://public.example/image.jpg'],
        'followers': ['secret-user-id'],
      }, docId: 'incident-1');
      expect(incident.reporterName, isEmpty);
      expect(incident.reporterTel, isEmpty);
      expect(incident.imageUrls, isEmpty);
      expect(incident.followers, isEmpty);
      expect(incident.latitude, 13.76);
    });
  });
}
