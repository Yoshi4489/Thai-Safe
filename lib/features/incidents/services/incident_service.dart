import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class IncidentService {
  IncidentService({FirebaseFirestore? firestore})
    : _incidents = (firestore ?? FirebaseFirestore.instance).collection(
        'incidents',
      );

  final CollectionReference<Map<String, dynamic>> _incidents;

  Stream<List<IncidentModel>> getIncidentsStream() {
    return _incidents
        .orderBy('created_at', descending: true)
        .limit(250)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IncidentModel.fromMap(doc.data(), docId: doc.id))
              .toList(growable: false),
        );
  }

  Stream<List<IncidentModel>> getIncidentsWithinKmRadius(
    double userLatitude,
    double userLongitude,
    double radiusKm,
  ) {
    return getIncidentsStream().map(
      (incidents) => incidents
          .where((incident) {
            final distanceM = Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              incident.latitude,
              incident.longitude,
            );
            return distanceM <= radiusKm * 1000;
          })
          .toList(growable: false),
    );
  }
}
