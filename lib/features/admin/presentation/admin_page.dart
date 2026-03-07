import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/admin/provider/admin_state_provider.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        Expanded(child: _statCard("Incidents", incidentController.totalIncidents.toString(), Colors.red)),
        const SizedBox(width: 10),
        Expanded(child: _statCard("Pending", incidentController.pendingIncidents.toString(), Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _statCard("Resolved", incidentController.resolvedIncidents.toString(), Colors.green)),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _adminActions(BuildContext context) {
    return Column(
      children: [
        _actionTile(
          icon: Icons.warning_amber_rounded,
          title: "Manage Incidents",
          subtitle: "View and update incident status",
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.verified_user,
          title: "Rescue Approval",
          subtitle: "Approve rescue team accounts",
          onTap: () {},
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.grey.shade100,
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _recentIncidents() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Flood reported near ถนนสุขุมวิท",
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Text(
                "Pending",
                style: TextStyle(color: Colors.orange),
              )
            ],
          ),
        );
      },
    );
  }
}