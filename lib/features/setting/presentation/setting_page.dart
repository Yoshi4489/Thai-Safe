import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/rescue_approval/service/rescue_approval_service.dart';
import 'package:thai_safe/features/setting/presentation/pages/edit_profile_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          /// Profile & Medical
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Profile & Medical",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Edit Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),

          const Divider(),

          /// Preferences
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Preferences",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            trailing: const Text("English"),
            onTap: () {},
          ),

          const Divider(),

          /// Support
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Support",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help Center"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("Report a Problem"),
            onTap: () {},
          ),

          const Divider(),

          /// Account
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Account",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 12),
          _requestRescueTile(context, ref.watch(authControllerProvider).user),

          const SizedBox(height: 30),

          /// App Version
          const Center(
            child: Text(
              "ThaiSafe v1.0.0",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _requestRescueTile(BuildContext context, dynamic currentUser) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.medical_services, color: Colors.blue.shade700),
        title: Text(
          "Request To Be Rescue",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            final name =
                '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'
                    .trim();
            await RescueApprovalService().createRescueRequest(
              userId: currentUser.id,
              name: name.isEmpty ? 'ไม่ระบุชื่อ' : name,
              phone: currentUser.tel ?? '',
            );

            if (context.mounted) {
              Navigator.pop(context); // ปิดโหลด
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("ส่งคำขอสำเร็จ! กรุณารอ Admin อนุมัติ"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // ปิดโหลด
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
