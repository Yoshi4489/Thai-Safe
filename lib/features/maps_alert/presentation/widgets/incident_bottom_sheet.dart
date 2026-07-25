import 'package:flutter/material.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/incident_details_page.dart';

class IncidentBottomSheet {
  static Future<void> show(
    BuildContext context,
    dynamic incidentValue,
    dynamic currentUser,
  ) async {
    final incident = incidentValue as IncidentModel;
    final role = currentUser?.role?.toString().toLowerCase() ?? 'user';
    final responder = role == 'responder' || role == 'admin';
    final repository = SafetyFunctionsRepository();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(label: Text(incident.status.replaceAll('_', ' '))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${incident.type} • ${incident.urgency}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                incident.details['summary']?.toString().isNotEmpty == true
                    ? incident.details['summary'].toString()
                    : 'No public details were added.',
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.blueGrey.shade50,
                child: const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Approximate public location'),
                  subtitle: Text(
                    'Reporter identity, phone number, exact location, medical '
                    'details, and protected photos are not public.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Follow'),
                      onPressed: () async {
                        try {
                          await repository.followIncident(incident.id, true);
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Incident notifications enabled.'),
                            ),
                          );
                        } catch (error) {
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                IncidentDetailsPage(incident: incident),
                          ),
                        );
                      },
                      child: Text(responder ? 'Responder view' : 'Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
