import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../data/incident_model.dart';

class IncidentService {
  final CollectionReference<Map<String, dynamic>> _incidentsRef =
      FirebaseFirestore.instance.collection('incidents');
  final geo = GeoFlutterFire();

  final Reference _storageRef = FirebaseStorage.instance.ref().child(
    'incident_proofs',
  );

  Future<void> createIncident(
    IncidentModel incident
  ) async {

    Map<String, dynamic> data = incident.toMap();

    await _incidentsRef.doc(incident.id).set(data);
  }

  Stream<List<IncidentModel>> getIncidentsStream() {
    return _incidentsRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return IncidentModel.fromMap(doc.data(), docId: doc.id);
            } catch (e) {
              print('Error parsing incident ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  Stream<List<IncidentModel>> getIncidentsWithinKmRadius(
    double userLat,
    double userLng,
    double radiusInKm,
  ) {
    final center = geo.point(latitude: userLat, longitude: userLng);

    return geo
        .collection(collectionRef: _incidentsRef)
        .within(
          center: center,
          radius: radiusInKm,
          field: 'position',
          strictMode: true,
        )
        .map(
          (docs) => docs
              .map(
                (doc) => IncidentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  docId: doc.id,
                ),
              )
              .toList(),
        );
  }
}
