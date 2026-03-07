import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/admin/provider/admin_state_provider.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  Function(int) onNavigate;
  AdminHomePage({super.key, required this.onNavigate});
  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ADMIN WELCOME
            _adminWelcome(),

            const SizedBox(height: 24),

            /// STATISTICS
            const Text(
              "System Overview",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _dashboardStats(ref),

            const SizedBox(height: 24),

            /// QUICK ACTIONS
            const Text(
              "Admin Actions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _adminActions(context),

            const SizedBox(height: 24),

            /// RECENT INCIDENTS
            const Text(
              "Recent Incidents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _recentIncidents(),
          ],
        ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _adminWelcome() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings, size: 36, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "ThaiSafe Admin System\nManage incidents and rescue teams",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardStats(WidgetRef ref) {
    final incidentController = ref.watch(adminIncidentControllerProvider);
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Incidents",
            incidentController.isLoading
                ? CircularProgressIndicator()
                : Text(
                    incidentController.totalIncidents.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
            Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            "Pending",
            incidentController.isLoading
                ? CircularProgressIndicator()
                : Text(
                    incidentController.pendingIncidents.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            "Resolved",
            incidentController.isLoading
                ? CircularProgressIndicator()
                : Text(
                    incidentController.resolvedIncidents.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, Widget value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [value, const SizedBox(height: 4), Text(title)]),
    );
  }

  Widget _adminActions(BuildContext context) {
    return Column(
      children: [
        _actionTile(
          icon: Icons.warning_amber_rounded,
          title: "Manage Incidents",
          subtitle: "View and update incident status",
          onTap: () {
            setState(() {
              widget.onNavigate(1);
            });
          },
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.verified_user,
          title: "Rescue Approval",
          subtitle: "Approve rescue team accounts",
          onTap: () {
            widget.onNavigate(2);
          },
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.grey.shade100,
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _recentIncidents() {
    final incidentStatus = {
      "Pending": Colors.orange,
      "Resolved": Colors.green,
      "Acknowledged": Colors.blue,
      "In Progress": Colors.blueGrey,
      "Cancelled": Colors.red,
    };

    final adminIncident = ref.watch(adminIncidentControllerProvider);

    if (adminIncident.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminIncident.recentIncidents.isEmpty) {
      return const Center(child: Text("No recent incidents"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: adminIncident.recentIncidents.length,
      itemBuilder: (context, index) {
        final recentIncident = adminIncident.recentIncidents[index];

        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: 6,
          ), // space between items
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300, // border color
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            title: Text("${recentIncident.title}"),
            subtitle: Text(
              "Status: ${recentIncident.status}",
              style: TextStyle(
                color: incidentStatus[recentIncident.status] ?? Colors.black,
              ),
            ),
            leading: const Icon(Icons.location_pin, color: Colors.red),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
