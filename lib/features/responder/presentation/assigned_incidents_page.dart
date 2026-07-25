import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/incident_details_page.dart';

class AssignedIncidentsPage extends StatelessWidget {
  const AssignedIncidentsPage({super.key});

  Stream<List<IncidentModel>> _stream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final assignments = FirebaseFirestore.instance
        .collection('incident_assignments')
        .where('lead_responder_uid', isEqualTo: uid)
        .orderBy('updated_at', descending: true)
        .snapshots();
    await for (final snapshot in assignments) {
      final incidents = await Future.wait(
        snapshot.docs.map((assignment) async {
          final incident = await FirebaseFirestore.instance
              .collection('incidents')
              .doc(assignment.id)
              .get();
          if (!incident.exists) return null;
          return IncidentModel.fromMap(incident.data()!, docId: incident.id);
        }),
      );
      yield incidents.whereType<IncidentModel>().toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My assigned incidents'),
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final incidents = snapshot.data!;
          if (incidents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No assigned incidents. Accept a pending incident from the '
                  'map to become its lead responder.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: Text(incident.title),
                  subtitle: Text(
                    '${incident.type} • '
                    '${incident.status.replaceAll('_', ' ')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => IncidentDetailsPage(incident: incident),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
