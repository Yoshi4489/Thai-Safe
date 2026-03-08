import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class IncidentManagementService {
  final CollectionReference<Map<String, dynamic>> _incidentRef =
      FirebaseFirestore.instance.collection("incidents");

  Stream<List<IncidentModel>> getIncidentByStatus(String status) {
    return _incidentRef
        .where("status", isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IncidentModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }
}
