import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class IncidentManagementService {
  IncidentManagementService({
    FirebaseFirestore? firestore,
    SafetyFunctionsRepository? functions,
  }) : _incidents = (firestore ?? FirebaseFirestore.instance).collection(
         'incidents',
       ),
       _functions = functions ?? SafetyFunctionsRepository();

  final CollectionReference<Map<String, dynamic>> _incidents;
  final SafetyFunctionsRepository _functions;

  Stream<List<IncidentModel>> getIncidentByStatus(String status) {
    final canonical = IncidentModel.normalizeIncidentStatus(status);
    // During migration, read all statuses and normalize legacy spellings.
    return _incidents.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => IncidentModel.fromMap(doc.data(), docId: doc.id))
          .where((incident) => incident.status == canonical)
          .toList(growable: false),
    );
  }

  Future<void> updateIncidentStatus(String incidentId, String status) async {
    final canonical = IncidentModel.normalizeIncidentStatus(status);
    if (canonical == 'assigned') {
      await _functions.acceptIncident(incidentId);
      return;
    }
    await _functions.transitionStatus(
      incidentId: incidentId,
      status: canonical,
      note: 'Administrator status update',
    );
  }
}
