import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:thai_safe/features/incident_management/provider/incident_management_state_provider.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/incident_details_page.dart';
import 'package:thai_safe/core/widgets/skeleton_loading.dart';

class IncidentManagementPage extends ConsumerStatefulWidget {
  const IncidentManagementPage({super.key});

  @override
  ConsumerState<IncidentManagementPage> createState() =>
      _IncidentManagementPageState();
}

class _IncidentManagementPageState
    extends ConsumerState<IncidentManagementPage> {
  String selectedStatus = "Pending";

  final List<String> statusList = [
    "Pending",
    "Acknowledged",
    "In Progress",
    "Resolved",
    "Cancelled",
  ];

  List<IncidentModel> getCurrentIncidents(IncidentManagementState state) {
    switch (selectedStatus) {
      case "Pending":
        return state.pendingIncidents;
      case "Acknowledged":
        return state.acknowledgeIncidents;
      case "In Progress":
        return state.inProgressIncidents;
      case "Resolved":
        return state.resolvedIncidents;
      case "Cancelled":
        return state.cancelledIncidents;
      default:
        return [];
    }
  }

  void _showChangeStatusDialog(BuildContext context, IncidentModel incident) {
    String selected = incident.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Incident Status"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: statusList.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selected = value!;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Update"),
              onPressed: () async {
                await ref
                    .read(incidentManagementControllerProvider.notifier)
                    .updateIncidentStatus(incident.id, selected);

                await ref
                    .read(incidentManagementControllerProvider.notifier)
                    .loadIncidentByStatus(selectedStatus);

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentManagementController = ref.watch(
      incidentManagementControllerProvider,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Incident Management",
          style: TextStyle(fontSize: 14),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          /// STATUS FILTER
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              itemCount: statusList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statusList[index];
                final isSelected = status == selectedStatus;

                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (_) async {
                    setState(() {
                      selectedStatus = status;
                    });
                    await ref
                        .read(incidentManagementControllerProvider.notifier)
                        .loadIncidentByStatus(status);
                  },
                );
              },
            ),
          ),

          const Divider(),

          /// INCIDENT LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(incidentManagementControllerProvider.notifier)
                    .loadIncidentByStatus(selectedStatus);
              },
              child: incidentManagementController.isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => SkeletonIncidentManagementCard(),
                    )
                  : _incidentCard(
                      context,
                      getCurrentIncidents(incidentManagementController),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(BuildContext context, List<IncidentModel> incidents) {
    final incidentStatus = {
      "Pending": Colors.orange,
      "Resolved": Colors.green,
      "Acknowledged": Colors.blue,
      "In Progress": Colors.blueGrey,
      "Cancelled": Colors.red,
    };
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: incidents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TYPE
              Text(
                incidents[index].title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              /// LOCATION
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Latitude: ${incidents[index].latitude.toStringAsFixed(2)}, Longitude: ${incidents[index].longitude.toStringAsFixed(2)}",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              /// TIME
              Text(
                DateFormat(
                  "EEEE, MMM d, yyyy",
                ).format(incidents[index].createdAt),
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              /// ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: incidentStatus[incidents[index].status]!
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      incidents[index].status,
                      style: TextStyle(
                        color: incidentStatus[incidents[index].status],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IncidentDetailsPage(
                                incident: incidents[index],
                              ),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showChangeStatusDialog(context, incidents[index]);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
