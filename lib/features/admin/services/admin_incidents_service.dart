import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class AdminIncidentsService {
  final CollectionReference<Map<String, dynamic>> _incidentsRef =
      FirebaseFirestore.instance.collection('incidents');

  Future<int> getTotalIncidents() async {
    final snapshot = await _incidentsRef.get();
    return snapshot.size;
  }

  Future<int> getIncidentsByStatus(String status) async {
    final snapshot = await _incidentsRef
        .where('status', isEqualTo: status)
        .get();
    return snapshot.size;
  }

Stream<List<IncidentModel>> getRecentlyIncidents() {
  return _incidentsRef
      .orderBy('created_at', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => IncidentModel.fromMap(doc.data(), docId: doc.id))
          .toList());
}
}
