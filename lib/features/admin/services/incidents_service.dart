import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentsService {
  final CollectionReference<Map<String, dynamic>> _incidentsRef =
      FirebaseFirestore.instance.collection('incidents');
  
  Future<int> getTotalIncidents() async {
    final snapshot = await _incidentsRef.get();
    return snapshot.size;
  }

  Future<int> getIncidentsByStatus(String status) async {
    final snapshot = await _incidentsRef.where('status', isEqualTo: status).get();
    return snapshot.size;
  }
}
