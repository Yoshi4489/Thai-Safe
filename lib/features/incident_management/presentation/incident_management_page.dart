import 'package:flutter/material.dart';

class IncidentManagementPage extends StatefulWidget {
  const IncidentManagementPage({super.key});

  @override
  State<IncidentManagementPage> createState() => _IncidentManagementPageState();
}

class _IncidentManagementPageState extends State<IncidentManagementPage> {

  String selectedStatus = "Pending";

  final List<String> statusList = [
    "Pending",
    "Acknowledged",
    "In Progress",
    "Resolved",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident Management"),
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
                  onSelected: (_) {
                    setState(() {
                      selectedStatus = status;
                    });
                  },
                );
              },
            ),
          ),

          const Divider(),

          /// INCIDENT LIST
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _incidentCard(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(BuildContext context) {
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
          const Text(
            "Flood Report",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          /// LOCATION
          const Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Expanded(child: Text("Near ถนนสุขุมวิท")),
            ],
          ),

          const SizedBox(height: 4),

          /// TIME
          const Text(
            "Reported: 12:30 PM",
            style: TextStyle(color: Colors.grey),
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
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Pending",
                  style: TextStyle(color: Colors.orange),
                ),
              ),

              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      // open incident detail
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // change status
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}